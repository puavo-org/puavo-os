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

        self.type = PROGRAM_TYPE_DESKTOP

        # Internal ID
        self.name = None

        # Displayed in the button
        self.title = title

        self.description = description
        self.keywords = []

        # Icon loaded through IconCache
        self.icon = icon

        # If true, this program has been conditionally hidden
        self.hidden = False

        # If true, the .desktop file for this (desktop) program is
        # missing or it could not be loaded because it was invalid
        self.missing_desktop = False

        # If true, the icon is a full path to an actual image file
        # instead of a generic name that we have to search for in
        # the icon directories
        self.icon_is_path = False

        # If false, this program is defined but not actually used
        self.used = False

        # The actual command line for desktop and custom programs;
        # URL for web links
        self.command = command

        # How many times this program has been launched? Used to
        # keep track of faves.
        self.uses = 0

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

        # Internal ID
        self.name = None

        self.title = title
        self.description = description

        # Icon loaded through IconCache
        self.icon = icon

        # If true, this menu has been conditionally hidden
        self.hidden = False

        # If false, this menu is defined but not actually used in
        # any category.
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

        # Internal ID
        self.name = None

        self.title = title
        self.position = 0

        # If true, this category has been conditionally hidden
        self.hidden = False

        # Zero or more menu IDs/instances
        self.menus = menus or []

        # Zero or more program IDs/instances
        self.programs = programs or []


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
        import re

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

        matches = sorted(matches, key=lambda program: program.title)

        return matches


    def load(self):
        import time
        import logging
        import os.path

        from iconcache import ICONS48
        from loader import load_menu_data
        from utils import log_elapsed_time
        import conditionals
        from settings import SETTINGS
        from constants import ICON_EXTENSIONS

        # Files/strings to be loaded
        sources = [
            ['f', 'menudata.yaml'],
            #['s', koodi],
        ]

        # Paths for .desktop files
        desktop_dirs = [
            '/usr/share/applications',
            '/usr/share/applications/kde4',
            '/usr/local/share/applications',
        ]

        # Where to search for icons
        icon_dirs = [
            '/usr/share/icons/hicolor/48x48/apps',
            '/usr/share/icons/hicolor/64x64/apps',
            '/usr/share/icons/hicolor/128x128/apps',
            '/usr/share/icons/Neu/128x128/categories',
            '/usr/share/icons/hicolor/scalable/apps',
            '/usr/share/icons/hicolor/scalable',
            '/usr/share/icons/Faenza/categories/64',
            '/usr/share/icons/Faenza/apps/48',
            '/usr/share/icons/Faenza/apps/96',
            '/usr/share/app-install/icons',
            '/usr/share/pixmaps',
            '/usr/share/icons/hicolor/32x32/apps',
        ]

        conditional_files = [
            'conditions.yaml'
        ]

        for src in sources:
            if src[0] == 'f':
                src[1] = SETTINGS.menu_dir + src[1]

        start_time = time.clock()

        # Load and evaluate conditionals
        for fname in conditional_files:
            result = conditionals.evaluate_file(SETTINGS.menu_dir + fname)
            self.conditions.update(result)

        conditional_time = time.clock()

        log_elapsed_time('Conditional evaluation time',
                         start_time, conditional_time)

        id_to_path_mapping = {}

        # Load menu data
        try:
            self.programs, \
            self.menus, \
            self.categories, \
            self.category_index = load_menu_data(sources,
                                                 desktop_dirs,
                                                 self.conditions)
        except Exception as exception:
            logging.error('Could not load menu data!')
            logging.error(exception, exc_info=True)
            return False

        if not self.programs:
            # No programs at all?
            return False

        parsing_time = time.clock()

        # Locate and load icon files
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
        log_elapsed_time('Icon loading time', parsing_time, end_time)
        log_elapsed_time('Total loading time', start_time, end_time)

        return True
