# Loads, updates and maintains user programs

import os
import logging
from pathlib import Path
import time
import utils

import menudata
import loaders.menudata_loader as menudata_loader
import loaders.dotdesktop_loader


# Loads the .desktop file for a single program and builds
# a program object out of it
def __load_user_program(program,            # a UserProgram instance
                        filename,           # .desktop file name
                        icon_locator,       # where to find icons
                        icon_cache,         # the icon cache to use
                        language):          # language code

    # Load the .desktop file
    try:
        desktop_data = loaders.dotdesktop_loader.load(filename)

        if 'Desktop Entry' not in desktop_data:
            raise RuntimeError('missing "Desktop Entry" section')
    except Exception as exc:
        logging.error(
            'Could not load the desktop file "%s" for user program:',
            filename)
        logging.error(str(exc))
        return False

    # If the .desktop file was created by us, reject it, because
    # otherwise we'd end up creating loops
    if 'X-Puavomenu-Created' in desktop_data['Desktop Entry']:
        logging.warning(
            '.desktop file "%s" was created by us, not adding it to the user programs list',
            filename
        )
        return False

    # Normally this would contain all the data loaded from menudata JSON
    # file(s), but those don't exist here
    final_data = {}

    menudata_loader.merge_json_and_desktop_data(
        final_data, desktop_data['Desktop Entry'], language)

    if final_data.get('command', None) is None:
        logging.warning('.desktop file "%s" does not specify a command to run',
                        filename)
        return False

    program.name = final_data.get('name', '<No name>')
    program.command = final_data.get('command', None)
    program.description = final_data.get('description', None)
    program.keywords = final_data.get('keywords', frozenset())

    # Locate the icon file
    icon_name = final_data.get('icon', None)
    icon_file, _ = icon_locator.locate_icon(icon_name)

    if program.original_icon_name:
        if program.original_icon_name == icon_file:
            # This program was reloaded, but the icon did not change
            return True

        # The icon did change, remove the old icon
        del icon_cache[program.original_icon_name]

    # Set the new icon
    if icon_file:
        try:
            program.icon, usable = icon_cache.load_icon(icon_file)
        except BaseException as e:
            logging.error(
                'User program icon not loaded, load_icon() threw an exception: %s',
                str(e))
            program.icon = None
            usable = False

        if not usable:
            logging.warning('Found icon "%s" for user program "%s" (file "%s"), ' \
                            'but the icon could not be loaded',
                            icon_name, program.name, filename)
    else:
        if icon_name:
            logging.warning('Unable to locate icon "%s" for user program "%s" (file "%s")',
                            icon_name, program.name, filename)
        else:
            logging.warning('User program "%s" (file "%s") has no icon defined for it',
                            program.name, filename)
        program.icon = None

    program.original_icon_name = icon_name

    return True


# Scans the user programs directory and creates, removes and updates
# user programs
def update(base_dir,     # where user programs are located in
           programs,     # all programs
           category,     # the category where user programs are in
           icon_locator, # where to find icons
           icon_cache,   # the icon cache to use
           language):    # language code

    if base_dir is None:
        return False        # "nothing changed"

    if not os.path.isdir(base_dir) or not os.access(base_dir, os.R_OK):
        logging.warning(
            "user_programs.update(): can't access directory \"%s\"", base_dir)
        return False

    start_time = time.perf_counter()

    # Collect the IDs of user programs, for change detection
    existing_user_programs = set()

    for pid, program in programs.items():
        if isinstance(program, menudata.UserProgram):
            existing_user_programs.add(pid)

    something_changed = False
    seen = set()

    # Detect new and changed files
    for name in Path(base_dir).rglob('*.desktop'):
        # Need some kind of a unique ID for this program. Use the original
        # filename and prefix it with something that can be used only
        # internally. Assume the original .desktop file name contains
        # something that can be used to uniquely identify the program.
        basename = os.path.splitext(name.name)[0]
        program_id = 'user-program-' + basename

        try:
            s = os.stat(name)

            if program_id in programs:
                # This program already exists. Has it changed?
                program = programs[program_id]

                # TODO: Also check the CRC-32 checksum of the file
                if program.modified != s.st_mtime or program.size != s.st_size:
                    # Yes, reload it
                    if __load_user_program(program, name, icon_locator,
                                           icon_cache, language):
                        program.modified = s.st_mtime
                        program.size = s.st_size
                    else:
                        logging.error('Changed user program "%s" not updated', name)

                seen.add(program_id)
                something_changed = True
            else:
                # A new .desktop file has been added
                program = menudata.UserProgram()

                program.menudata_id = program_id
                program.original_desktop_file = os.path.basename(name)
                program.filename = name
                program.modified = s.st_mtime
                program.size = s.st_size

                if __load_user_program(program, name, icon_locator,
                                       icon_cache, language):
                    programs[program_id] = program
                    seen.add(program_id)
                    something_changed = True

        except Exception as exception:
            # Don't let a single failed program take down everything
            logging.fatal('Could not load user program "%s":', name)
            logging.error(exception, exc_info=True)

    # Detect removed .desktop files
    removed_user_programs = existing_user_programs - seen

    for pid in removed_user_programs:
        program = programs[pid]

        if program.icon and program.original_icon_name:
            del icon_cache[program.original_icon_name]

        del programs[pid]
        something_changed = True

    if something_changed:
        # Rebuild the list of programs in the specified user category
        prog_list = []

        for pid in seen:
            prog_list.append((pid, programs[pid].name.lower()))

        # the files can be in arbitrary order, so sort
        # the user programs alphabetically
        prog_list.sort(key=lambda p: p[1])

        category.program_ids = []

        for p in prog_list:
            category.program_ids.append(p[0])

    end_time = time.perf_counter()

    utils.log_elapsed_time('user_programs.update(): user programs update',
                           start_time, end_time)

    return something_changed
