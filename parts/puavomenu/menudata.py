# Core menu data definitions

import re

from enum import IntEnum


# puavo-pkg program installer status
class PuavoPkgState(IntEnum):
    UNKNOWN = -1
    NOT_INSTALLED = 0
    INSTALLED = 1


class ProgramFlags(IntEnum):
    HIDDEN = 0x01

    BROKEN = 0x02

    # the icon name is a full path to an image file, otherwise it's
    # a "generic" name that must be searched for
    ICON_NAME_IS_PATH = 0x04

    # this program is actually referenced somewhere
    USED = 0x08


class MenuFlags(IntEnum):
    HIDDEN = 0x01
    USED = 0x02


class CategoryFlags(IntEnum):
    HIDDEN = 0x01
    USED = 0x02
    USER_CATEGORY = 0x04


# Container for dirs.json
class DirsConfig:
    __slots__ = ('desktop_dirs', 'theme_icon_dirs', 'generic_icon_dirs')

    def __init__(self):
        # Directories where to look for .desktop files
        self.desktop_dirs = []

        # Zero or more theme-specific (theme names are their directory names
        # in /usr/share/icons) icon directories.
        self.theme_icon_dirs = {}

        # Generic icon directories, used when no theme-specific
        # icons could be found
        self.generic_icon_dirs = []


    def clear(self):
        self.desktop_dirs = []
        self.theme_icon_dirs = {}
        self.generic_icon_dirs = []


# Base class for all program types
class ProgramBase:
    __slots__ = (
        'menudata_id', 'name', 'description', 'icon', 'keywords',
        'flags', 'original_desktop_file', 'original_icon_name'
    )

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None):

        # Internal ID (the name given to this program in menudata files)
        self.menudata_id = None

        # Displayed in the button below the icon
        self.name = name

        # Optional description displayed in a hover text
        self.description = description

        # Icon loaded through IconCache
        self.icon = icon

        # Used during searching
        self.keywords = frozenset()

        # See ProgramFlags. Not all of them apply.
        self.flags = 0

        # These are needed when we're creating desktop icons and panel links.
        # Their values are not always known.
        self.original_desktop_file = None
        self.original_icon_name = None


    def __str__(self):
        return ''


# Desktop and custom programs use both this, as the only difference
# between them is that desktop programs have automatic .desktop file
# loading, but custom programs don't.
class Program(ProgramBase):
    __slots__ = ('command')

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 command=None):

        super().__init__(name, description, icon)

        # The actual command line to be executed
        self.command = command


    def __str__(self):
        return '<Program, id="{id}", name="{name}", ' \
               'description="{desc}" command="{cmd}", icon="{icon}" ' \
               'keywords={kw}>'. \
               format(id=self.menudata_id,
                      name=self.name,
                      desc=self.description,
                      cmd=self.command,
                      icon=self.icon,
                      kw=self.keywords)


# A puavo-pkg program launcher/installer
class PuavoPkgProgram(Program):
    __slots__ = ('package_id', 'state', 'installer_icon', 'raw_menudata')

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 command=None):

        super().__init__(name, description, icon)

        self.package_id = None
        self.state = PuavoPkgState.UNKNOWN
        self.installer_icon = None

        # A copy of the "raw" menudata loaded from the menudata JSON files.
        # Needed, because when a puavopkg program is installed, it must go
        # through the same motions as any other program. This data can be
        # empty, if there was nothing special configured for the program.
        self.raw_menudata = None


    def is_installer(self):
        # Can only install programs that aren't installed yet
        return self.state == PuavoPkgState.NOT_INSTALLED


# User-defined programs
class UserProgram(Program):
    __slots__ = ('command', 'filename', 'modified', 'size')

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 command=None):

        super().__init__(name, description, icon)

        # The actual command line to be executed
        self.command = command

        # For tracking .desktop file changes
        self.filename = None
        self.modified = None
        self.size = None


class WebLink(ProgramBase):
    __slots__ = ('url')

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 url=None):

        super().__init__(name, description, icon)

        # The URL to be opened
        self.url = url


    def __str__(self):
        return '<WebLink, id="{id}", name="{name}", ' \
               'description="{desc}" url="{url}", icon="{icon}" ' \
               'keywords={kw}>'. \
               format(id=self.menudata_id,
                      name=self.name,
                      desc=self.description,
                      url=self.url,
                      icon=self.icon,
                      kw=self.keywords)


# Groups zero or more programs
class Menu:
    __slots__ = ('menudata_id', 'name', 'description', 'icon', 'flags',
                 'program_ids')

    def __init__(self,
                 name=None,
                 description=None,
                 icon=None,
                 program_ids=None):

        # Internal ID (the name given to this menu in menudata files)
        self.menudata_id = None

        # Displayed in the button below the icon
        self.name = name

        # Optional description displayed in a hover text
        self.description = description

        # Icon loaded through IconCache
        self.icon = icon

        # See MenuFlags. Not all of them apply.
        self.flags = 0

        # Zero or more program IDs
        self.program_ids = program_ids or []


# Groups zero or more menus and programs
class Category:
    __slots__ = ('menudata_id', 'name', 'position', 'flags', 'menu_ids',
                 'program_ids')

    def __init__(self,
                 name=None,
                 menu_ids=None,
                 program_ids=None):

        # Internal ID (the name given to this category in menudata files)
        self.menudata_id = None

        # Displayed in the button below the icon
        self.name = name

        # For ordering categories. Can be negative.
        self.position = 0

        # See CategoryFlags. Not all of them apply.
        self.flags = 0

        # Zero or more menu IDs
        self.menu_ids = menu_ids or []

        # Zero or more program IDs
        self.program_ids = program_ids or []


# Wraps (almost) all of the above in a handy structure
class Menudata:
    __slots__ = ('programs', 'menus', 'categories', 'category_index')

    def __init__(self):
        self.programs = {}
        self.menus = {}
        self.categories = {}
        self.category_index = []


    # Searches for programs, returns them sorted by their names
    def search(self, key, skip_puavopkg_installers):
        matches = []

        for _, program in self.programs.items():
            if re.search(key, program.menudata_id, re.IGNORECASE):
                matches.append(program)
                continue

            if re.search(key, program.name, re.IGNORECASE):
                matches.append(program)
                continue

            # Check the .desktop file name if it's available
            if program.original_desktop_file is not None:
                if re.search(
                        key,
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
