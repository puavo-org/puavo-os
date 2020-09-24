# Parses a bunch of .json files, filters it with conditionals and tags,
# locates and loads icons, deals with puavo-pkg programs, and finally
# spits out usable menu data

import os
import glob
import re
import logging
import time

import utils

import filters.tags
import filters.conditionals

import loaders.json_loader
import loaders.dotdesktop_loader

import menudata
from menudata import ProgramFlags, MenuFlags, CategoryFlags

import puavopkg


# Pattern for menudata files ("XX-name.json" where XX is a two-digit number)
MENU_FILE_PATTERN = re.compile(r'^\d\d')


# Finds menu JSON files. They must be sorted by priority and name.
# If you have the following files:
#
#    foo/bar/50-default.json
#    foo/bar/51-fixes.json
#
# This function will return this (the files can be in any order):
#
# [
#    (51, 'fixes', 'foo/bar/51-fixes.json')
#    (50, 'default', 'foo/bar/50-default.json')
# ]
def find_menu_files(*where):
    files = []

    for full_name in glob.iglob(os.path.join(*where, '*.json')):
        name = os.path.basename(full_name)
        number = MENU_FILE_PATTERN.search(name)

        if not number:
            continue

        name, _ = os.path.splitext(name)

        # The first two elements are for sorting (numbers first, then
        # names), the third element is the actual name you want to use
        # after sorting.
        files.append((number.group(0), name[number.end(0)+1:], full_name))

    return files


# Sort the filename tuples and return a list of just filenames.
# So if you have this:
#
# [
#     ('51', 'fixes', 'foo/bar/51-fixes.json')
#     ('50', 'default', 'foo/bar/50-default.json'),
# ]
#
# Then this function will return you this:
# [
#     'foo/bar/50-default.json',
#     'foo/bar/51-fixes.json'
# ]
def sort_menu_files(files):
    return [name[2] for name in sorted(files, key=lambda i: (i[0], i[1]))]


# "Intelligently" merge two dicts. Allows the second dict to remove entries
# that exist in the first dict.
def merge_dicts_intelligently(a, b):
    # Duplicate the first dict as-is
    if a:
        c = dict(a)
    else:
        c = {}

    # Then add new items from the second dict, and replace those
    # that have a value, and delete those who have a None value.
    if b:
        for k, v in b.items():
            if k == 'id':
                # never touch the ID
                continue

            if k in c:
                # test against 'None' so zeros and Falses and
                # other non-True values will work without
                # triggering value removals
                if v is None:
                    del c[k]
                else:
                    c[k] = v
            else:
                # add a new value, even if it's None
                c[k] = v

    return c


# An "intelligent" replacement for dict.merge(). Adds new entries, but
# uses merge_dicts_intelligently() to update existing entries. Used
# when mergging multiple menudata files together.
def merge_raw_data(existing, new):
    for new_id, new_item in new.items():
        if new_id in existing:
            # update
            existing[new_id] = merge_dicts_intelligently(existing[new_id], new_item)
        else:
            # add
            existing[new_id] = new_item


# Scans one or more directories, looking for the specified .desktop file.
# Returns None if nothing could be found.
def locate_desktop_file(desktop_dirs, filename):
    for dir_name in desktop_dirs:
        full = os.path.join(dir_name, filename)

        if os.path.isfile(full):
            return full

    return None


# Non-destructively merges dicts containing data from JSON files and
# .desktop files
def merge_json_and_desktop_data(json_data, desktop_data, language):
    # For every item we *DON'T* have in JSON data, load it from the desktop
    # data. This way we can partially or fully override anything specified in
    # .desktop files, while still allowing .desktop files to specify data.

    # Load the program name
    if 'name' not in json_data:
        key = 'Name[%s]' % language

        if key not in desktop_data:
            key = 'GenericName[%s]' % language

            if key not in desktop_data:
                key = 'Name'

        if key in desktop_data:
            json_data['name'] = desktop_data[key]

    # Load the description
    if 'description' not in json_data:
        key = 'Comment[%s]' % language

        if key in desktop_data:
            json_data['description'] = desktop_data[key]
        else:
            # Use a "generic" English description if "en" description does
            # not exist. Yes this is a hack, thanks for asking.
            if language == 'en' and 'Comment' in desktop_data:
                json_data['description'] = desktop_data['Comment']

    # Extract search keywords
    # TODO: Support per-language keywords in JSON files
    key = 'Keywords[%s]' % language

    if key not in desktop_data:
        key = 'Keywords'

    if key in desktop_data:
        temp = set(filter(None, desktop_data[key].split(";")))
    else:
        temp = set()

    if 'keywords' in json_data:
        json_data['keywords'].update(temp)
    else:
        json_data['keywords'] = temp

    # Get the icon name. These can be localised too, but we ignore that
    # and plow through and hope it'll work.
    if ('icon' not in json_data or json_data['icon'] is None) and \
        ('Icon' in desktop_data):
        json_data['icon'] = str(desktop_data['Icon'])

    # Command line / URL
    if ('command' not in json_data or json_data['command'] is None) and \
        ('Exec' in desktop_data):
        json_data['command'] = str(desktop_data['Exec'])

    # Store categories as tags
    if 'Categories' in desktop_data:
        tags = set()

        # Annoyingly, .desktop files use semicolons here
        # but we use just spaces/commas
        for raw_cat in filter(None, desktop_data['Categories'].split(';')):
            cat = raw_cat.strip()

            if cat:
                tags.add(cat.lower())

        if tags:
            if 'tags' in json_data:
                json_data['tags'].update(tags)
            else:
                json_data['tags'] = tags


# Locates and loads .desktop files for desktop programs (including
# puavo-pkg programs)
def load_desktop_files(programs, desktop_dirs, language):
    for pid, program in programs.items():
        if not program['flags'] & menudata.ProgramFlags.USED:
            continue

        if program['type'] != 'desktop':
            continue

        # Skip puavopkg programs that aren't installed yet. Their .desktop
        # files don't exist in the filesystem.
        if 'puavopkg' in program and 'state' in program['puavopkg'] and \
           program['puavopkg']['state'] != menudata.PuavoPkgState.INSTALLED:
            continue

        desktop_file = locate_desktop_file(desktop_dirs, pid + '.desktop')

        if desktop_file is None:
            logging.warning(
                'Can\'t find the desktop file for program "%s", program ignored',
                pid)

            program['flags'] |= menudata.ProgramFlags.BROKEN
            continue

        try:
            desktop_data = loaders.dotdesktop_loader.load(desktop_file)

            if 'Desktop Entry' not in desktop_data:
                raise RuntimeError('missing "Desktop Entry" section')
        except Exception as exc:
            logging.error(
                'Could not load the desktop file "%s" for program "%s":',
                desktop_file, pid)
            logging.error(str(exc))

            program['flags'] |= menudata.ProgramFlags.BROKEN
            continue

        # Load the parts we don't have yet from the .desktop file
        merge_json_and_desktop_data(program, desktop_data['Desktop Entry'], language)

        # Keep track of the original desktop file name. We need it,
        # for example, when creating panel icons.
        program['original_desktop_file'] = desktop_file


# Locates and loads icon files for programs and menus
def load_icons(programs, menus, icon_locator, icon_cache):
    num_missing_icons = 0

    # --------------------------------------------------------------------------
    # Load program icons

    for menudata_id, program in programs.items():
        # Initially there are no icons
        program['icon_handle'] = None

        if program['flags'] & ProgramFlags.BROKEN:
            continue

        if not program['flags'] & ProgramFlags.USED:
            continue

        # ----------------------------------------------------------------------
        # First deal with puavopkg programs that aren't installed yet. Their
        # icon names are always a full path to an icon file.

        if 'puavopkg' in program and 'state' in program['puavopkg'] and \
           program['puavopkg']['state'] != menudata.PuavoPkgState.INSTALLED:
            icon_name = program['puavopkg']['icon']

            program['icon_handle'], usable = icon_cache.load_icon(icon_name)

            if not usable:
                logging.error('Could not load the puavopkg installer icon "%s" for program "%s"',
                              icon_name, menudata_id)
                program['icon_handle'] = None
                num_missing_icons += 1

            continue

        # ----------------------------------------------------------------------

        if 'icon' not in program:
            # This should never happen. Because if a .desktop file has
            # no icon (for some reason), then the menudata has been
            # patched to define an icon. But... everything can break.
            logging.error('Program "%s" has no icon at all', menudata_id)
            program['icon_handle'] = None
            num_missing_icons += 1
            continue

        # Needed when creating desktop and panel icons. Let GNOME deal
        # with locating the icon file.
        program['original_icon_name'] = program['icon']

        # ----------------------------------------------------------------------
        # Locate the icon file

        icon_path, is_path = icon_locator.locate_icon(program['icon'], 48)

        if icon_path is None:
            logging.warning("Can't find icon \"%s\" for program \"%s\"",
                            program['icon'], menudata_id)
            program['icon_handle'] = None
            num_missing_icons += 1
            continue

        program['icon'] = icon_path

        # ----------------------------------------------------------------------
        # Load the icon

        program['icon_handle'], usable = icon_cache.load_icon(icon_path)

        # This is not a fatal error. The program will still work, it'll just
        # look ugly.
        if not usable:
            logging.warning('Found icon "%s" for program "%s", but '
                            'it could not be loaded', icon_path, menudata_id)
            num_missing_icons += 1

        if is_path:
            program['flags'] |= menudata.ProgramFlags.ICON_NAME_IS_PATH

    # --------------------------------------------------------------------------
    # Load menu icons

    # Less stuff going on here, because menus don't have to remember
    # the original icon name or anything like that.
    for menu_id, menu in menus.items():
        # No icons at all at first
        menu['icon_handle'] = None

        if ('icon' not in menu) or (menu['icon'] is None):
            logging.warning('Menu "%s" has no icon defined', menu_id)
            num_missing_icons += 1
            continue

        icon_path, is_path = icon_locator.locate_icon(menu['icon'], 48)

        if icon_path is None:
            logging.warning("Can't find icon \"%s\" for menu \"%s\"",
                            menu['icon'], menu_id)
            menu['icon'] = None
            num_missing_icons += 1
            continue

        menu['icon_handle'], usable = icon_cache.load_icon(icon_path)

        if not usable:
            logging.warning('Found an icon "%s" for menu "%s", but '
                            'it could not be loaded', menu['icon'], menu_id)
            num_missing_icons += 1

    # --------------------------------------------------------------------------

    if num_missing_icons:
        logging.info('Have %d missing or unloadable icons', num_missing_icons)
    else:
        logging.info('No missing icons')


# Finds the best translated string for the current language in progams,
# menus and categrories
def localize_entries(programs, menus, categories, language):
    for _, prog in programs.items():
        if not prog['flags'] & menudata.ProgramFlags.USED:
            continue

        if 'name' in prog:
            prog['name'] = utils.localize(prog['name'], language)

        if 'description' in prog:
            prog['description'] = utils.localize(prog['description'], language)

    for _, menu in menus.items():
        if not menu['flags'] & menudata.MenuFlags.USED:
            continue

        if 'name' in menu:
            menu['name'] = utils.localize(menu['name'], language)

        if 'description' in menu:
            menu['description'] = utils.localize(menu['description'], language)

    for _, category in categories.items():
        if not category['flags'] & menudata.CategoryFlags.USED:
            continue

        if 'name' in category:
            category['name'] = utils.localize(category['name'], language)


# Sort the categories by position, but if the positions are identical,
# sort by names. Warning: the sort is not locale-aware or case
# insensitive!
def sort_categories(categories):
    temp_index = []

    for cid, category in categories.items():
        if category['flags'] & MenuFlags.BROKEN or \
           category['flags'] & MenuFlags.HIDDEN:
            continue

        if not category['flags'] & MenuFlags.USED:
            continue

        position = 0

        if 'position' in category:
            try:
                position = int(category['position'])
            except Exception:
                logging.warning('Cannot interpret "%s" as a position for '
                                'category "%s", defaulting to 0',
                                category['position'], cid)

        temp_index.append((position, cid))

    temp_index.sort(key=lambda cat: (cat[0], cat[1]))

    return [i[1] for i in temp_index]


def load(menudata_files,        # data source
         language,              # what language to use
         desktop_dirs,          # directories for .desktop files
         tags, conditionals,    # visibility filtering
         puavopkg_states,       # current puavo-pkg program install states
         icon_locator,          # icon file locator
         icon_cache):           # cache for icons

    programs = {}
    menus = {}
    categories = {}

    # --------------------------------------------------------------------------
    # Load menudata files

    start_time = time.perf_counter()

    for name in menudata_files:
        try:
            logging.info('Loading menudata file "%s"', name)

            with open(name, mode='r', encoding='utf-8') as f:
                json_string = f.read()

            p, m, c = loaders.json_loader.load_raw_menudata(json_string, name)

            merge_raw_data(programs, p)
            merge_raw_data(menus, m)
            merge_raw_data(categories, c)
        except Exception as exc:
            # don't let one failed file stop the whole process,
            # even if it can cause missing/incomplete menus
            logging.error(exc, exc_info=True)
            continue

    end_time = time.perf_counter()
    utils.log_elapsed_time('Raw menudata loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Deal with puavo-pkg program states. This must be done early, because
    # many things depend on the current installation state. It is also done
    # to all programs, even to those that will be broken, hidden or unused
    # and thus will not appear in the menu. init_programs() is not a heavy
    # function, it's mostly dict lookups and some ifs.

    start_time = time.perf_counter()

    puavopkg.init_programs(programs, puavopkg_states)

    # Duplicate raw program definitions for puavo-pkg programs, so they can
    # be merged with the .desktop file data when the program is intalled.
    for pid, program in programs.items():
        if 'puavopkg' in program:
            program['raw_menudata'] = dict(program)

    end_time = time.perf_counter()
    utils.log_elapsed_time('puavopkg state init time', start_time, end_time)

    # --------------------------------------------------------------------------
    # There could be programs that are defined, but not actually used in any
    # menu or category. Mark all referenced programs as "used" and skip
    # the unmarked programs when .desktop files are loaded.

    for cid, category in categories.items():
        category['flags'] |= CategoryFlags.USED

        if 'menus' in category:
            for mid in category['menus']:
                if mid in menus:
                    menus[mid]['flags'] |= MenuFlags.USED

        if 'programs' in category:
            for pid in category['programs']:
                if pid in programs:
                    programs[pid]['flags'] |= ProgramFlags.USED

    for mid, menu in menus.items():
        if not menu['flags'] & MenuFlags.USED:
            continue

        if 'programs' in menu:
            for pid in menu['programs']:
                if pid in programs:
                    programs[pid]['flags'] |= ProgramFlags.USED

    # --------------------------------------------------------------------------
    # Localize names and descriptions

    # Must be done before .desktop files are loaded, as the dict merge
    # algorithm cannot merge dicts with strings

    localize_entries(programs, menus, categories, language)

    # --------------------------------------------------------------------------
    # Locate and load .desktop files for desktop programs

    start_time = time.perf_counter()

    load_desktop_files(programs, desktop_dirs, language)

    end_time = time.perf_counter()
    utils.log_elapsed_time('.desktop file loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Find nameless entries

    for pid, program in programs.items():
        if program.get('name', None) is None:
            logging.error('Program "%s" has no name, skipping', pid)
            program['flags'] |= ProgramFlags.BROKEN
            continue

    for mid, menu in menus.items():
        if menu.get('name', None) is None:
            logging.error('Menu "%s" has no name, skipping', mid)
            menu['flags'] |= MenuFlags.BROKEN
            continue

    for cid, category in categories.items():
        if category.get('name', None) is None:
            logging.error('Category "%s" has no name, skipping', cid)
            category['flags'] |= CategoryFlags.BROKEN
            continue

    # --------------------------------------------------------------------------
    # Apply tags and conditionals and do visibility filtering

    # This cannot be done earlier, because .desktop files can contain
    # tags and other things that must be taken into account here.

    start_time = time.perf_counter()

    # All programs are hidden by default
    for name, program in programs.items():
        program['flags'] |= ProgramFlags.HIDDEN

    # Apply "hidden_by_default" flags
    for name, program in programs.items():
        # Programs can be made visible by default
        if 'hidden_by_default' in program and program['hidden_by_default'] is False:
            program['flags'] &= ~ProgramFlags.HIDDEN

    for name, menu in menus.items():
        # Menus can be made hidden by default
        if 'hidden_by_default' in menu and menu['hidden_by_default'] is True:
            menu['flags'] |= MenuFlags.HIDDEN

    for name, cat in categories.items():
        # Categories can be made hidden by default
        if 'hidden_by_default' in cat and cat['hidden_by_default'] is True:
            cat['flags'] |= CategoryFlags.HIDDEN

    # Process tags
    if tags.have_data():
        # Programs first
        for name, program in programs.items():
            if program['flags'] & ProgramFlags.BROKEN:
                continue

            # No tags -> program is always hidden, no matter what
            if 'tags' not in program or not program['tags']:
                logging.warning('Program "%s" has no tags, forcibly hiding it', name)
                program['flags'] |= ProgramFlags.HIDDEN
                continue

            for a in tags.actions:
                # apply categorical tags
                if a.target == filters.tags.Action.TAG:
                    if a.name in program['tags']:
                        if a.action == filters.tags.Action.SHOW:
                            program['flags'] &= ~ProgramFlags.HIDDEN
                        else:
                            logging.debug('Tag "%s" hides program "%s"', a.original, name)
                            program['flags'] |= ProgramFlags.HIDDEN

                # apply per-program tags
                elif a.target == filters.tags.Action.PROGRAM:
                    if a.name == name:
                        if a.action == filters.tags.Action.SHOW:
                            logging.debug('Tag "%s" shows program "%s"', a.original, name)
                            program['flags'] &= ~ProgramFlags.HIDDEN
                        else:
                            logging.debug('Tag "%s" hides program "%s"', a.original, name)
                            program['flags'] |= ProgramFlags.HIDDEN

        # Then menus
        for a in tags.actions:
            if a.target != filters.tags.Action.MENU:
                continue

            if a.name not in menus:
                continue

            menu = menus[a.name]

            if menu['flags'] & MenuFlags.BROKEN:
                continue

            if a.action == filters.tags.Action.SHOW:
                logging.debug('Tag "%s" shows menu "%s"', a.original, a.name)
                menu['flags'] &= ~MenuFlags.HIDDEN
            else:
                logging.debug('Tag "%s" hides menu "%s"', a.original, a.name)
                menu['flags'] |= MenuFlags.HIDDEN

        # Finally categories
        for a in tags.actions:
            if a.target != filters.tags.Action.CATEGORY:
                continue

            if a.name not in categories:
                continue

            cat = categories[a.name]

            if cat['flags'] & CategoryFlags.BROKEN:
                continue

            if a.action == filters.tags.Action.SHOW:
                logging.debug('Tag "%s" shows category "%s"', a.original, a.name)
                cat['flags'] &= ~CategoryFlags.HIDDEN
            else:
                logging.debug('Tag "%s" hides category "%s"', a.original, a.name)
                cat['flags'] |= CategoryFlags.HIDDEN

    # Apply conditionals. They can override tags, to allow per-user
    # customisations (we have no per-user puavoconf).
    if conditionals:
        for name, program in programs.items():
            if program['flags'] & ProgramFlags.BROKEN:
                continue

            if 'condition' in program:
                if filters.conditionals.is_hidden(conditionals,
                                                  program['condition'],
                                                  name,
                                                  'program'):
                    program['flags'] |= ProgramFlags.HIDDEN
                else:
                    program['flags'] &= ~ProgramFlags.HIDDEN

        for name, menu in menus.items():
            if menu['flags'] & MenuFlags.BROKEN:
                continue

            if 'condition' in menu:
                if filters.conditionals.is_hidden(conditionals,
                                                  menu['condition'],
                                                  name,
                                                  'menu'):
                    menu['flags'] |= MenuFlags.HIDDEN
                else:
                    menu['flags'] &= ~MenuFlags.HIDDEN

        for name, cat in categories.items():
            if cat['flags'] & CategoryFlags.BROKEN:
                continue

            if 'condition' in cat:
                if filters.conditionals.is_hidden(conditionals,
                                                  cat['condition'],
                                                  name,
                                                  'category'):
                    cat['flags'] |= CategoryFlags.HIDDEN
                else:
                    cat['flags'] &= ~CategoryFlags.HIDDEN

    # Then find all used programs again. We've processed tags and
    # conditionals, so we know what menus and categories are actually
    # visible. But because menus and programs cannot be visible without
    # categories, go through all menus in every visible category and
    # mark them as "used". Then propagate this flag down to programs.
    for _, program in programs.items():
        program['flags'] &= ~ProgramFlags.USED

    for _, menu in programs.items():
        menu['flags'] &= ~MenuFlags.USED

    for cid, category in categories.items():
        if category['flags'] & CategoryFlags.BROKEN or \
           category['flags'] & CategoryFlags.HIDDEN:
            continue

        if 'menus' in category:
            for mid in category['menus']:
                if mid in menus:
                    menus[mid]['flags'] |= MenuFlags.USED

        if 'programs' in category:
            for pid in category['programs']:
                if pid in programs:
                    programs[pid]['flags'] |= ProgramFlags.USED

    for mid, menu in menus.items():
        if menu['flags'] & MenuFlags.BROKEN or \
           menu['flags'] & MenuFlags.HIDDEN:
            continue

        # If a menu isn't used by any category, remove it
        if not menu['flags'] & MenuFlags.USED:
            logging.info('Menu "%s" is not actually used in any visible category',
                         mid)
            continue

        if 'programs' in menu:
            for pid in menu['programs']:
                if pid in programs:
                    programs[pid]['flags'] |= ProgramFlags.USED

    # Remove everyhing that's unused, hidden or missing
    removed_programs = set()
    removed_menus = set()
    removed_categories = set()

    temp = {}

    for pid, program in programs.items():
        flags = program['flags']

        # remove broken programs (don't update 'removed_programs' here, as we
        # want warnings about references to broken programs to be visible)
        if flags & ProgramFlags.BROKEN:
            continue

        # remove hidden programs
        if flags & ProgramFlags.HIDDEN:
            removed_programs.add(pid)
            continue

        # remove unused programs
        if not flags & ProgramFlags.USED:
            logging.info('Program "%s" is not actually used in any visible category or menu',
                         pid)
            removed_programs.add(pid)
            continue

        temp[pid] = program

    programs = temp

    temp = {}

    for mid, menu in menus.items():
        flags = menu['flags']

        # remove broken menus
        if menu['flags'] & MenuFlags.BROKEN:
            removed_menus.add(mid)
            continue

        # remove hidden menus
        if flags & MenuFlags.HIDDEN:
            removed_menus.add(mid)
            continue

        # remove unused menus
        if not flags & MenuFlags.USED:
            removed_menus.add(mid)
            continue

        temp[mid] = menu

    menus = temp

    temp = {}

    for cid, cat in categories.items():
        flags = cat['flags']

        # remove broken categories
        if category['flags'] & CategoryFlags.BROKEN:
            removed_categories.add(cid)
            continue

        # remove hidden categories
        if flags & CategoryFlags.HIDDEN:
            removed_categories.add(cid)
            continue

        # remove unused categories
        if not flags & CategoryFlags.USED:
            removed_categories.add(cid)
            continue

        temp[cid] = cat

    categories = temp

    # Weed out invalid entries from menu and category submenu/program lists
    for cid, category in categories.items():
        if 'menus' in category:
            good = []

            for mid in category['menus']:
                if mid in menus:
                    good.append(mid)
                    continue

                if mid not in removed_menus:
                    logging.warning(
                        'Category "%s" references to a non-existent menu "%s"',
                        cid, mid)

            category['menus'] = good

        if 'programs' in category:
            good = []

            for pid in category['programs']:
                if pid in programs:
                    good.append(pid)
                    continue

                if pid not in removed_programs:
                    logging.warning(
                        'Category "%s" references to a non-existent program "%s"',
                        cid, pid)

            category['programs'] = good

    for mid, menu in menus.items():
        if 'programs' in menu:
            good = []

            for pid in menu['programs']:
                if pid in programs:
                    good.append(pid)
                    continue

                if pid not in removed_programs:
                    logging.warning(
                        'Menu "%s" references to a non-existent program "%s"',
                        mid, pid)

            menu['programs'] = good

    end_time = time.perf_counter()
    utils.log_elapsed_time('Filtering/conditionals time', start_time, end_time)

    # From this point on, all remaining categories, menus and programs are
    # valid, visible and can be used. Their icons are not yet loaded and
    # some of the icons may be missing, but that won't prevent the programs
    # from being used.

    # --------------------------------------------------------------------------
    # Sort categories by their positions

    category_index = sort_categories(categories)

    logging.debug('Final category order: %s', category_index)

    # --------------------------------------------------------------------------
    # Locate and load icons for programs and menus. This is one of the
    # heaviest and slowest parts.

    start_time = time.perf_counter()

    try:
        load_icons(programs, menus, icon_locator, icon_cache)
    except BaseException as e:
        logging.error('Unable to load program icons!')
        logging.error(e, exc_info=True)

    end_time = time.perf_counter()
    utils.log_elapsed_time('Icon loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Convert the dicts into nicer objects. Then we don't have to
    # constantly check if a dict key exists or not.

    start_time = time.perf_counter()

    md = menudata.Menudata()

    for pid, src in programs.items():
        # No program that is hidden or unused should make it this far, because
        # they're removed in the above loops. But if they somehow get here,
        # this is the final "firewall" that makes them go away.
        if src['flags'] & ProgramFlags.BROKEN or \
           src['flags'] & ProgramFlags.HIDDEN:
            continue

        if not src['flags'] & ProgramFlags.USED:
            continue

        name = src.get('name', None)
        desc = src.get('description', None)
        icon = src.get('icon_handle', None)

        if src['type'] == 'desktop':
            if 'puavopkg' in src and src['puavopkg'] is not None:
                dst = menudata.PuavoPkgProgram(name, desc, icon)
                dst.package_id = src['puavopkg']['id']
                dst.state = src['puavopkg']['state']

                if 'icon' in src['puavopkg']:
                    dst.installer_icon = src['puavopkg']['icon']

                dst.raw_menudata = dict(src['raw_menudata'])
            else:
                dst = menudata.Program(name, desc, icon)

            dst.command = src.get('command', None)
        elif src['type'] == 'custom':
            dst = menudata.Program(name, desc, icon)
            dst.command = src.get('command', None)
        elif src['type'] == 'web':
            dst = menudata.WebLink(name, icon=icon)
            dst.url = src.get('url', None)

            # For web links, show the URL in the description tooltip
            if desc is not None:
                dst.description = f'{desc}\n({dst.url})'
            else:
                dst.description = dst.url

        dst.menudata_id = pid
        dst.keywords = frozenset(src.get('keywords', ()))

        # Needed when creating desktop icons and panel links
        dst.original_desktop_file = src.get('original_desktop_file', None)
        dst.original_icon_name = src.get('original_icon_name', None)

        md.programs[pid] = dst

    for mid, src in menus.items():
        if src['flags'] & MenuFlags.BROKEN or \
           src['flags'] & MenuFlags.HIDDEN:
            continue

        if not src['flags'] & MenuFlags.USED:
            continue

        dst = menudata.Menu(
            name=src.get('name', '<No name>'),
            description=src.get('description', None),
            icon=src.get('icon_handle', None))

        dst.program_ids = src.get('programs', [])
        md.menus[mid] = dst

    for cid, src in categories.items():
        if src['flags'] & CategoryFlags.BROKEN or \
           src['flags'] & CategoryFlags.HIDDEN:
            continue

        if not src['flags'] & CategoryFlags.USED:
            continue

        dst = menudata.Category(name=src.get('name', '<No name>'))
        dst.menu_ids = src.get('menus', [])
        dst.program_ids = src.get('programs', [])
        md.categories[cid] = dst

    md.category_index = category_index

    end_time = time.perf_counter()
    utils.log_elapsed_time('Final conversion time', start_time, end_time)

    logging.info('Programs: %d  Menus: %d  Categories: %d',
                 len(md.programs), len(md.menus), len(md.categories))

    # --------------------------------------------------------------------------

    return md
