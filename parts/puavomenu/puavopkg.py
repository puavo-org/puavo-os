# puavo-pkg stuff

import logging
import os.path

import utils
import menudata
import loaders.menudata_loader
import loaders.dotdesktop_loader


# Where installed puavo-pkg programs are placed in
PACKAGE_DIRECTORY = '/var/lib/puavo-pkg/installed'


# A placeholder icon used for puavo-pkg programs that are not installed yet
# *and* and don't specify a installer custom icon
INSTALLER_ICON = '/usr/share/icons/Faenza/apps/48/system-installer.png'


# Detect dynamic installed/not-installed states for every listed package
def detect_package_states(id_string):
    pkg_ids = str(id_string).split(' ') if id_string else []
    pkg_ids = filter(None, pkg_ids)
    pkg_ids = set(pkg_ids)

    states = {}

    for pkg_id in pkg_ids:
        states[pkg_id] = os.path.exists(os.path.join(PACKAGE_DIRECTORY, pkg_id))

    return states


# Sets up puavo-pkg program states (installed/not installed, etc.) and
# deals with their icons and other things. Called from menudata_loader.py.
def init_programs(programs, puavopkg_states):
    for pid, program in programs.items():
        if program['type'] != 'desktop':
            continue

        if 'puavopkg' not in program:
            continue

        if not isinstance(program['puavopkg'], dict):
            continue

        if 'id' not in program['puavopkg']:
            logging.error(
                'program "%s" has a puavopkg section, but it contains no package ID',
                pid)

            # This is *always* a configuration error, but it's so rare that
            # there's no point in trying to handle intelligently.
            del program['puavopkg']
            continue

        if program['puavopkg']['id'] not in puavopkg_states:
            # puavo.pkgs.ui.pkglist only lists programs that can be dynamically
            # installed/uninstalled, so because this program is not on the list,
            # we can assume it is part of the desktop image. From our perspective,
            # the program is not a puavo-pkg program anymore. "Convert" it into
            # a normal desktop program to prevent it from being installed or
            # uninstalled.
            logging.info(
                'puavo-pkg program "%s" is already part of the desktop image',
                pid)

            del program['puavopkg']
            continue

        # This program is installed through puavo-pkg and its
        # .desktop files/etc. might not always be available.
        puavopkg = program['puavopkg']
        puavopkg['state'] = menudata.PuavoPkgState.UNKNOWN

        if 'icon' not in puavopkg:
            # No custom installer icon defined, use the stock icon
            puavopkg['icon'] = INSTALLER_ICON

        if puavopkg_states[puavopkg['id']]:
            # This program is already installed and can be used normally
            puavopkg['state'] = menudata.PuavoPkgState.INSTALLED
        else:
            # This puavo-pkg program is valid, but it has not
            # been installed yet. Requires special handling.
            puavopkg['state'] = menudata.PuavoPkgState.NOT_INSTALLED

            logging.info(
                'puavo-pkg program "%s" (ID "%s") has not been installed yet',
                puavopkg['id'], pid)


# Converts a working program object back into an installer
# Called from reload_program() below, do not call manually
def __program_uninstalled(program, icon_cache):
    # Unload the old icon
    if program.icon:
        old_icon = icon_cache.index_to_filename(program.icon)

        if old_icon:
            logging.info('__program_uninstalled(): unloading old icon "%s"',
                         old_icon)
            icon_cache.unload_icon(old_icon)

    # Restore the old icon (either the stock installer icon, or the custom icon)
    icon_name = INSTALLER_ICON

    if program.installer_icon:
        icon_name = program.installer_icon

    logging.info('__program_uninstalled(): restoring installer icon "%s"',
                 icon_name)

    usable = False

    if os.path.isfile(icon_name):
        program.icon, usable = icon_cache.load_icon(icon_name)

    if not usable:
        logging.error('__program_uninstalled(): unable to load the installer icon ' \
                      '"%s" for removed program "%s"', icon_name, program.menudata_id)

    program.state = menudata.PuavoPkgState.NOT_INSTALLED

    return True


# Converts an installer into a working program object
# Called from reload_program() below, do not call manually
def __program_installed(program, language, desktop_dirs, icon_locator, icon_cache):
    # TODO: Deduplicate this mess. There's lots of copy-pasting from main.py
    # and elsewhere in here.

    # Locate the .desktop file
    desktop_file = loaders.menudata_loader.locate_desktop_file(
        desktop_dirs, program.menudata_id + '.desktop')

    if desktop_file is None:
        logging.error('__program_installed(): .desktop file for program "%s" not found',
                      program.menudata_id)
        return False

    logging.info('__program_installed(): Found the desktop file: "%s"', desktop_file)

    # Try to load it
    try:
        desktop_data = loaders.dotdesktop_loader.load(desktop_file)
    except Exception as exception:
        logging.error('__program_installed(): Could not load file "%s" for program "%s": %s',
                      desktop_file, program.menudata_id, str(exception))
        return False

    if 'Desktop Entry' not in desktop_data:
        logging.error('__program_installed(): Rejecting desktop file "%s" for "%s": No "[Desktop Entry]" ' \
                      'section in the file', desktop_file, program.menudata_id)
        return False

    # Merge the raw menudata with the newly-loaded .desktop data
    new_menudata = dict(program.raw_menudata)

    loaders.menudata_loader.merge_json_and_desktop_data(
        new_menudata, desktop_data['Desktop Entry'], language)

    # Try to load the icon file
    icon_name = new_menudata.get('icon', None)
    icon_file, _ = icon_locator.locate_icon(icon_name)

    # Update the program object
    program.name = new_menudata.get('name', '<No name>')
    program.description = new_menudata.get('description', None)

    if icon_file:
        program.icon, usable = icon_cache.load_icon(icon_file)

        if not usable:
            logging.error(
                '__program_installed(): Found icon "%s" for puavo-pkg program "%s", ' \
                'but the file could not be loaded', icon_file, program.menudata_id)
            program.icon = None

        # Make desktop link icons work
        program.original_icon_name = icon_name
    else:
        logging.error(
            '__program_installed(): puavo-pkg program "%s" has no icon',
            program.menudata_id)
        program.icon = None
        program.original_icon_name = None

    program.command = new_menudata.get('command', None)
    program.keywords = frozenset(new_menudata.get('keywords', ()))
    program.original_desktop_file = new_menudata.get('original_desktop_file', None)

    program.state = menudata.PuavoPkgState.INSTALLED

    return True


# Reloads a single puavo-pkg program and detects installation/uninstallation
# state changes
def reload_program(program,
                   puavopkg_states,     # *NEW* puavo-pkg install states
                   language,
                   desktop_dirs,
                   icon_locator,
                   icon_cache):

    if not isinstance(program, menudata.PuavoPkgProgram):
        logging.error('Some idiot called puavopkg.reload_program with a non-puavopkg program object!')
        return False

    # --------------------------------------------------------------------------
    # Detect the state change. 'puavopkg_states' contains NEW states.

    pkg_id = program.package_id

    if pkg_id not in puavopkg_states:
        logging.error('reload_program(): program "%s" is part of the desktop image, '
                      'doing nothing', pkg_id)
        return False

    old_state = program.state

    if puavopkg_states[pkg_id]:
        new_state = menudata.PuavoPkgState.INSTALLED
    else:
        new_state = menudata.PuavoPkgState.NOT_INSTALLED

    logging.info('reload_program(): puavo-pkg program "%s":', pkg_id)
    logging.info('  old state: %s', old_state)
    logging.info('  new state: %s', new_state)

    if old_state == new_state:
        logging.info('    -> no changes')
        return False

    # --------------------------------------------------------------------------
    # Alter the program state. Return a new program object that the
    # old program can be simply replaced with.

    import time

    total_start = time.perf_counter()

    success = False

    if old_state == menudata.PuavoPkgState.INSTALLED and \
       new_state == menudata.PuavoPkgState.NOT_INSTALLED:
        # This program has been uninstalled
        logging.info('reload_program(): puavo-pkg program "%s" has been uninstalled',
                     pkg_id)

        success = __program_uninstalled(program, icon_cache)
    else:
        # This program has been installed
        logging.info('reload_program(): puavo-pkg program "%s" has been installed',
                     pkg_id)

        success = __program_installed(program, language, desktop_dirs,
                                      icon_locator, icon_cache)

    # --------------------------------------------------------------------------

    end_time = time.perf_counter()

    utils.log_elapsed_time('puavopkg program reload time', total_start, end_time)

    return success
