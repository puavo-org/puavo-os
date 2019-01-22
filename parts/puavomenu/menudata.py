# Core menu data types. Menu data loading.

from constants import PROGRAM_TYPE_DESKTOP


# Python has no structs, so classes are (ab)used instead. namedtuples
# could be used, but they're classes in disguise, so let's cut out the
# middle man. Because we're not expecting to actually add new program
# types any time soon, OOP is not actualy used; you won't find
# type-specific parsing or launching methods here. It's just data.

class Program:
    """Programs, web links, etc."""

    def __init__(self,
                 title=None,
                 description=None,
                 icon=None,
                 command=None):

        # Type of this program. Affects mostly how it is launched
        # and how is added on the desktop or the bottom panel.
        self.type = PROGRAM_TYPE_DESKTOP

        # Internal ID (the name given to this program in menudata files)
        self.name = None

        # Displayed in the button below the icon
        self.title = title

        # Optional description displayed in a hover text
        self.description = description

        # Used during searching
        self.keywords = []

        # The actual command line for desktop and custom programs;
        # URL for web links
        self.command = command

        # How many times this program has been launched. Used to
        # keep track of faves ("most often used programs").
        self.uses = 0

        # Icon loaded through IconCache
        self.icon = icon

        # Either a generic name for the icon, or an actual path to the
        # icon file.
        self.icon_name = None

        # If true, icon_name is a full path to an actual image file.
        # If false, icon_name is a "generic" icon name and we must
        # search for the actual file.
        self.icon_name_is_path = False

        # If true, this program has been conditionally hidden. Load-time
        # only, hidden programs are removed before final menu data is built.
        self.hidden = False

        # If true, the .desktop file for this (desktop) program is
        # missing or it could not be loaded because it was invalid
        self.missing_desktop = False

        # If false, this program has been defined but not actually used
        self.used = False

        # If set, this is the name of the original .desktop file
        # the data was read from. Not always known or applicable.
        self.original_desktop_file = None


    def __str__(self):
        return '<Program, type={0}, name="{1}", name="{2}", ' \
               'description="{3}" command="{4}", icon="{5}">'. \
               format(self.type,
                      self.name,
                      self.title,
                      self.description,
                      self.command,
                      self.icon)


class Menu:
    """Groups zero or more programs."""

    def __init__(self,
                 title=None,
                 description=None,
                 icon=None,
                 programs=None):

        # Internal ID (the name given to this menu in menudata files)
        self.name = None

        # Displayed in the button below the icon
        self.title = title

        # Optional description displayed in a hover text
        self.description = description

        # Icon loaded through IconCache
        self.icon = icon

        # Full path to the icon file. Generic icon names are not accepted
        # for men definitions.
        self.icon_name = None

        # If true, this menu has been conditionally hidden. Load-time
        # only, hidden menus are removed before final menu data is built.
        self.hidden = False

        # If false, this menu has been defined but not actually used
        self.used = False

        # Zero or more program IDs (during load time) or actual
        # references (after loading is done).
        self.programs = programs or []


class Category:
    """Groups multiple menus and programs."""

    def __init__(self,
                 title=None,
                 menus=None,
                 programs=None):

        # Internal ID (the name given to this category in menudata files)
        self.name = None

        # Displayed in the button below the icon
        self.title = title

        # For ordering categories. Can be negative.
        self.position = 0

        # If true, this category has been conditionally hidden
        self.hidden = False

        # Zero or more menu IDs/instances
        self.menus = menus or []

        # Zero or more program IDs/instances
        self.programs = programs or []


import re

MENU_FILE_PATTERN = re.compile('^\d\d-')


def find_menu_files(*where):
    import glob
    import os

    files = []

    for full_name in glob.iglob(os.path.join(*where, '*.yml')):
        name = os.path.basename(full_name)
        number = MENU_FILE_PATTERN.search(name)

        if number:
            # The first two elements are for sorting (numbers first, then
            # names), the third element is the actual name you want to use
            # after sorting.
            files.append((number.group(0), name[number.end(0):], full_name))

    return files


class Menudata:
    """Top-level container for all menu data."""

    def __init__(self):
        # Conditions
        self.conditions = {}

        # All programs, indexed by their IDs
        self.programs = {}

        # All menus, indexed by their IDs
        self.menus = {}

        # All categories, indexed by their IDs
        self.categories = {}

        # A list of category IDs, in the order they appear on
        # the category switcher
        self.category_index = []


    # Searches for programs
    def search(self, key):
        matches = []

        for name in self.programs:
            program = self.programs[name]

            if not program.used:
                continue

            if re.search(key, program.title, re.IGNORECASE):
                matches.append(program)
                continue

            # check the .desktop file name
            if program.original_desktop_file:
                if re.search(key,
                             program.original_desktop_file.replace('.desktop', ''),
                             re.IGNORECASE):
                    matches.append(program)
                    continue

            # keyword search must be done last, otherwise a program
            # can appear multiple times in the search results
            for kwd in program.keywords:
                if re.search(key, kwd, re.IGNORECASE):
                    matches.append(program)
                    break

        matches = sorted(matches, key=lambda program: program.title.lower())

        return matches


    def load(self):
        import time
        import logging
        import os.path
        import json

        from settings import SETTINGS
        from iconcache import ICONS48
        from constants import ICON_EXTENSIONS
        import loader
        import utils
        import conditionals

        # Where to look for .desktop files
        desktop_dirs = []

        # Where to look for icons
        icon_dirs = []

        # Load the directories configuration file. This file is required,
        # so bail out if it fails. JSON is used because JSON is faster
        # to parse than YAML.
        dirs_name = os.path.join(SETTINGS.menu_dir, 'dirs.json')

        try:
            dirs = json.load(open(dirs_name,  'r', encoding='utf-8'))

            if 'desktop_dirs' in dirs:
                desktop_dirs = dirs['desktop_dirs']

            if 'icon_dirs' in dirs:
                icon_dirs = dirs['icon_dirs']
        except Exception as e:
            logging.error('Failed to load the directories config file "%s": %s',
                           dirs_name, str(e))
            return False

        # Get a list of all available condition and menudata files, then sort
        # them by priority and name. It's possible to scan multiple directories
        # here, but currently we don't use that functionality.
        condition_files = []
        menudata_files = []

        start_time = time.clock()

        condition_files += find_menu_files(SETTINGS.menu_dir, 'conditions')
        condition_files = sorted(condition_files, key=lambda i: (i[0], i[1]))

        menudata_files += find_menu_files(SETTINGS.menu_dir, 'menudata')
        menudata_files = sorted(menudata_files, key=lambda i: (i[0], i[1]))

        scan_time = time.clock()

        utils.log_elapsed_time('Condition and menudata files scanning time',
                               start_time, scan_time)

        # Load and evaluate conditions
        start_time = time.clock()

        logging.info('Have %d source(s) for conditions', len(condition_files))

        for name in condition_files:
            self.conditions.update(conditionals.evaluate_file(name[2]))

        conditions_time = time.clock()

        utils.log_elapsed_time('Conditions evaluation time',
                               start_time, conditions_time)

        # Load menu data
        start_time = time.clock()

        sources = [n[2] for n in menudata_files]

        try:
            self.programs, \
            self.menus, \
            self.categories, \
            self.category_index = loader.load_menu_data(sources,
                                                        desktop_dirs,
                                                        self.conditions)
        except Exception as exception:
            logging.error('Could not load menu data!')
            logging.error(exception, exc_info=True)
            return False

        parsing_time = time.clock()

        if not self.programs:
            # No programs at all?
            return False

        # Locate and load icon files
        id_to_path_mapping = {}

        logging.info('Loading icons...')
        num_missing_icons = 0

        for name in self.programs:
            program = self.programs[name]

            if not program.used:
                continue

            if program.icon is None:
                # This should not happen, ever
                logging.error('The impossible happened: program "%s" '
                              'has no icon at all!', name)
                num_missing_icons += 1
                continue

            if name in id_to_path_mapping:
                program.icon_is_path = True
                program.icon = id_to_path_mapping[name]

            if program.icon_is_path:
                # Just use it
                if os.path.isfile(program.icon):
                    icon = ICONS48.load_icon(program.icon)

                    if icon.usable:
                        program.icon = icon
                        continue

                # Okay, the icon was specified, but it could not be loaded.
                # Try automatic loading.
                program.icon_is_path = False

            # Locate the icon specified in the .desktop file
            icon_path = None

            for dirname in icon_dirs:
                # Try the name as-is first
                path = os.path.join(dirname, program.icon)

                if os.path.isfile(path):
                    icon_path = path
                    break

                if not icon_path:
                    # Then try the different extensions
                    for ext in ICON_EXTENSIONS:
                        path = os.path.join(dirname, program.icon + ext)

                        if os.path.isfile(path):
                            icon_path = path
                            break

                if icon_path:
                    break

            # Nothing found
            if not icon_path:
                logging.error('Icon "%s" for program "%s" not found in '
                              'icon load paths', program.icon, name)
                program.icon = None
                num_missing_icons += 1
                continue

            program.icon = ICONS48.load_icon(path)

            if not program.icon.usable:
                logging.warning('Found icon "%s" for program "%s", but '
                                'it could not be loaded', path, name)
                num_missing_icons += 1
            else:
                id_to_path_mapping[name] = path

        for name in self.menus:
            menu = self.menus[name]

            if menu.icon is None:
                logging.warning('Menu "%s" has no icon defined', name)
                num_missing_icons += 1
                continue

            if not os.path.isfile(menu.icon):
                logging.error('Icon "%s" for menu "%s" does not exist',
                              menu.icon, name)
                menu.icon = None
                num_missing_icons += 1
                continue

            menu.icon = ICONS48.load_icon(menu.icon)

            if not menu.icon.usable:
                logging.warning('Found an icon "%s" for menu "%s", but '
                                'it could not be loaded', path, name)
                num_missing_icons += 1

        end_time = time.clock()

        if num_missing_icons == 0:
            logging.info('No missing icons')
        else:
            logging.info('Have %d missing or unloadable icons',
                         num_missing_icons)

        stats = ICONS48.stats()
        logging.info('Number of 48-pixel icons cached: %d', stats['num_icons'])
        logging.info('Number of 48-pixel atlas surfaces: %d', stats['num_atlases'])
        utils.log_elapsed_time('Icon loading time', parsing_time, end_time)
        utils.log_elapsed_time('Total loading time', start_time, end_time)

        return True
