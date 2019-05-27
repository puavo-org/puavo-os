# Core menu data types. Menu data loading.

import re
from enum import Enum

# Program types. Desktop is the default.
class ProgramType(Enum):
    DESKTOP = 0
    CUSTOM = 1
    WEB = 2


# Python has no structs, so classes are (ab)used instead. namedtuples
# could be used, but they're classes in disguise, so let's cut out the
# middle man. Because we're not expecting to actually add new program
# types any time soon, OOP is not actualy used; you won't find
# type-specific parsing or launching methods here. It's just data.

class Program:
    """Programs, web links, etc."""

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 command=None):

        # Type of this program. Affects mostly how it is launched
        # and how is added on the desktop or the bottom panel.
        self.program_type = ProgramType.DESKTOP

        # Internal ID (the name given to this program in menudata files)
        self.menudata_id = None

        # Displayed in the button below the icon
        self.name = name

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

        # If false, this program has been defined but not actually used
        self.used = False

        # If set, this is the name of the original .desktop file
        # the data was read from. Not always known or applicable.
        self.original_desktop_file = None

    def __str__(self):
        return '<Program, type={0}, id="{1}", name="{2}", ' \
               'description="{3}" command="{4}", icon="{5}" ' \
               'keywords={6} hidden={7}>'. \
               format(self.program_type,
                      self.menudata_id,
                      self.name,
                      self.description,
                      self.command,
                      self.icon_name,
                      self.keywords,
                      self.hidden)


class Menu:
    """Groups zero or more programs."""

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 programs=None):

        # Internal ID (the name given to this menu in menudata files)
        self.menudata_id = None

        # Displayed in the button below the icon
        self.name = name

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
                 name=None,
                 menus=None,
                 programs=None):

        # Internal ID (the name given to this category in menudata files)
        self.menudata_id = None

        # Displayed in the button below the icon
        self.name = name

        # For ordering categories. Can be negative.
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

        # All programs, indexed by their menudata IDs
        self.programs = {}

        # All menus, indexed by their menudata IDs
        self.menus = {}

        # All categories, indexed by their menudata IDs
        self.categories = {}

        # A list of category menudata IDs, in the order they appear
        # in the category switcher
        self.category_index = []

    # Searches for programs, returns them sorted by their names
    def search(self, key):
        matches = []

        for _, program in self.programs.items():
            if program.hidden:
                continue

            if re.search(key, program.menudata_id, re.IGNORECASE):
                matches.append(program)
                continue

            if re.search(key, program.name, re.IGNORECASE):
                matches.append(program)
                continue

            # Check the .desktop file name
            if program.original_desktop_file:
                if re.search(key,
                             program.original_desktop_file.replace('.desktop', ''),
                             re.IGNORECASE):
                    matches.append(program)
                    continue

            # Keyword search must be done last, otherwise a program
            # can appear multiple times in the search results
            for kwd in program.keywords:
                if re.search(key, kwd, re.IGNORECASE):
                    matches.append(program)
                    break

        return sorted(matches, key=lambda program: program.name.lower())

    def clear(self):
        self.programs = {}
        self.menus = {}
        self.categories = {}
        self.category_index = []

    def load(self, language, menudata_root_dir, tag_filter_string, icon_cache):
        """A high-level interface to everything in loader.py. Loads all the
        menu data in the specified directory and builds usable menu data
        out of it."""

        # If Python allowed class implementation to be spread across multiple
        # files (like C++ does), I'd move this method to loader.py. Now it's
        # just a thin wrapper for everything in it.

        import loader

        self.programs, self.menus, self.categories, self.category_index = \
            loader.load_menu_data(language,
                                  menudata_root_dir,
                                  tag_filter_string,
                                  icon_cache)
