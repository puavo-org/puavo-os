# Core menu data types

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
