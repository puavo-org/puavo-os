# Utility classes for locating and storing hundreds of icons efficiently.

import os
import re
import logging

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gio
import cairo

import utils_gui


# Accepted extensions for icon files, in the order we prefer them. Some
# .desktop file "Icon" entries specify full paths, some only "generic"
# names, so to tell them apart, we check if the name has an extension.
ICON_EXTENSIONS = ('.svg', '.svgz', '.png', '.xpm', '.jpg', '.jpeg')


# Tracks unused and usable cells in a single atlas
class AtlasCell:
    __slots__ = ('free', 'usable')

    def __init__(self):
        # Is this atlas grid cell used?
        self.free = True

        # Is the icon stored at this atlas cell actually usable?
        self.usable = False


# Atlases cache and store one or more fixed-sized icons in a grid layout
class Atlas:
    __slots__ = ('cell', 'full', 'surface', 'context')

    def __init__(self, width, height, bitmap_size):
        # Create empty grid cells
        self.cell = []

        for y in range(0, height):
            for x in range(0, width):
                self.cell.append(AtlasCell())

        logging.info(
            'Atlas::ctor(): initialized a new %dx%d grid of cells', width, height)

        # Is this grid full? Used to speed up some lookup operations.
        self.full = False

        # Create a new backing bitmap
        self.surface = cairo.ImageSurface(
            cairo.FORMAT_ARGB32, bitmap_size, bitmap_size)

        self.context = cairo.Context(self.surface)

        # Fill the atlas image with nothingness (even the alpha channel) so
        # we can blit from it without messing up whatever's already behind
        # the icon
        self.context.save()
        self.context.set_source_rgba(0.0, 0.0, 0.0, 0.0)
        self.context.set_operator(cairo.OPERATOR_SOURCE)
        self.context.rectangle(0, 0, bitmap_size, bitmap_size)
        self.context.fill()
        self.context.restore()


    # Removes an icon from the backing bitmap
    def clear_surface_slot(self, y, x, icon_size):
        self.context.save()
        self.context.set_source_rgba(0.0, 0.0, 0.0, 0.0)
        self.context.set_operator(cairo.OPERATOR_SOURCE)
        self.context.rectangle(x * icon_size, y * icon_size, icon_size, icon_size)
        self.context.fill()
        self.context.restore()


# Reference-counted icon positions
class IconLookup:
    __slots__ = ('grid_index', 'uses', 'usable')

    def __init__(self, grid_index=-1, uses=0):
        self.grid_index = grid_index    # icon's location (grid, y, x)
        self.uses = uses                # refcount
        self.usable = False             # copied from the grid slot for quick access


class IconCache:
    __slots__ = ('grid_size', 'icon_size', 'bitmap_size', 'atlases', 'filenames')

    def __init__(self, bitmap_size, icon_size):
        # Each atlas is a grid containing NxN slots, compute the N.
        # We use 8-bit indexes for coordinates, so the maximum grid
        # size is 255x255.
        self.grid_size = bitmap_size // icon_size

        if self.grid_size > 255:
            raise RuntimeError(
                'the grid size for {0}x{0} icons on an {1}x{1} bitmap is too big ' \
                '({2}x{2}), reduce the bitmap size' \
                .format(icon_size, bitmap_size, self.grid_size))

        self.icon_size = icon_size
        self.bitmap_size = bitmap_size
        self.atlases = []

        logging.info('IconCache::ctor(): bitmap_size=%d, icon_size=%d, grid_size=%d',
                     self.bitmap_size, self.icon_size, self.grid_size)

        # filename -> IconLookup
        self.filenames = {}


    # Packs icon location in one 24-bit integer
    def pack_index(self, atlas, y, x):
        return ((atlas & 0xFF) << 16) | ((y & 0xFF) << 8) | (x & 0xFF)


    # Extracts icon location from a 24-bit integer
    def unpack_index(self, index):
        try:
            return ((index >> 16) & 0xFF, (index >> 8) & 0xFF, index & 0xFF)
        except BaseException as e:
            logging.error(str(e))
            logging.error(index)
            return 0


    # Loads a new icon or returns a cached copy
    def load_icon(self, filename):
        if filename in self.filenames:
            # We've loaded this icon already, return a cached copy
            cached = self.filenames[filename]
            cached.uses += 1

            return (cached.grid_index, cached.usable)

        # Must load a new icon. First, find a free slot.
        # Brute-force search goes brrrrr
        atlas_num = -1
        cell_num = -1

        for i, atlas in enumerate(self.atlases):
            if atlas.full:
                continue

            for j, cell in enumerate(atlas.cell):
                if cell.free:
                    atlas_num = i
                    cell_num = j
                    break

            if atlas_num == -1:
                atlas.full = True
            else:
                break

        if atlas_num == -1:
            # All atlas grids are full, create a new
            if self.atlases:
                self.atlases[-1].full = True

            self.atlases.append(Atlas(self.grid_size, self.grid_size, self.bitmap_size))

            # Start from the upper left corner
            atlas_num = len(self.atlases) - 1
            cell_y = 0
            cell_x = 0

            if len(self.atlases) > 255:
                raise RuntimeError('Created too many atlases. Increase the atlas bitmap size.')
        else:
            # Compute the X and Y coordinates of the free slot
            cell_y = cell_num // self.grid_size
            cell_x = cell_num % self.grid_size

        # cell_x and cell_y should never be -1 at this point, because
        # we simply keep creating new atlases until we find room

        # We have a free cell. Load the actual image file and place it in
        # the atlas.
        atlas = self.atlases[atlas_num]

        #print('Final index: %d  Entries: %d' % (cell_y * self.grid_size + cell_x, len(atlas.cell)))

        cell = atlas.cell[cell_y * self.grid_size + cell_x]

        index = self.pack_index(atlas_num, cell_y, cell_x)

        lookup = IconLookup(grid_index=index, uses=1)

        cell.free = False

        atlas.full = False

        try:
            icon_surface = utils_gui.load_image_at_size(
                filename, self.icon_size, self.icon_size)

            atlas.context.set_source_surface(
                icon_surface,
                cell_x * self.icon_size,
                cell_y * self.icon_size)

            atlas.context.paint()

            # mark the icon as usable
            cell.usable = True
            lookup.usable = True
        except Exception as e:
            msg = str(e)

            if msg == '':
                # this actually has happened
                msg = '<The exception has no message>'

            logging.error('Could not load icon "%s": %s', filename, msg)

        self.filenames[filename] = lookup

        # the returned value directly contains all three numbers
        return (index, cell.usable)


    # Does a reverse lookup and finds the original filename matching
    # the icon handle. This is a rarely used function and it isn't
    # very efficient. Returns None if nothing found.
    def index_to_filename(self, index):
        if index is None:
            return None

        for name, lookup in self.filenames.items():
            if lookup.grid_index == index:
                return name

        return None


    # Unloads a previously-loaded icon. If its reference count actually
    # drops to zero, the icon is cleared from its parent atlas.
    def unload_icon(self, filename):
        if filename not in self.filenames:
            return

        icon = self.filenames[filename]

        # update refcount
        icon.uses -= 1

        if icon.uses > 0:
            return

        # No one uses this icon anymore, remove it
        atlas_num, cy, cx = self.unpack_index(icon.grid_index)

        atlas = self.atlases[atlas_num]
        cell = atlas.cell[cy * self.grid_size + cx]

        atlas.clear_surface_slot(cy, cx, self.icon_size)
        cell.free = True
        cell.usable = False

        del self.filenames[filename]

        atlas.full = False


    def draw_icon(self, index, ctx, x, y):
        # locate the icon
        atlas_num, cy, cx = self.unpack_index(index)
        atlas = self.atlases[atlas_num]
        cell = atlas.cell[cy * self.grid_size + cx]

        # can it be drawn?
        if not cell.usable:
            return

        if cell.free:
            return

        # https://www.cairographics.org/FAQ/#paint_from_a_surface
        ctx.set_source_surface(
            atlas.surface,
            x - cx * self.icon_size,
            y - cy * self.icon_size)
        ctx.rectangle(x, y, self.icon_size, self.icon_size)
        ctx.fill()


    # handle []
    def __getitem__(self, filename):
        return self.load_icon(filename)


    # handle del
    def __delitem__(self, filename):
        self.unload_icon(filename)


    # called in development mode when menudata is cleared/reloaded
    def clear(self):
        self.atlases = []
        self.filenames = {}


    def stats(self):
        return {
            'num_icons': len(self.filenames),
            'num_atlases': len(self.atlases)
        }


def get_user_icon_dirs():
    # User program icons can be stored in $HOME/.local/share/icons. The icon
    # locator class (see below) cannot do recursive searches, so we must glob.

    # Perform rudimentary sorting, based on size designations in directory
    # names. Prioritize paths by icon sizes. If we have 32x32 and 64x64 icons,
    # load the 64x64 icon to prevent blurry blotches of pixels. In contrast,
    # the icon directories listed in dirs.json are manually sorted by
    # preference.

    user_icons_root = os.path.join(
        os.path.expanduser('~'), '.local', 'share', 'icons')

    number_extractor = re.compile(r'\d+')
    dirs = []

    for dir_tuple in os.walk(user_icons_root):
        name = dir_tuple[0]
        size = -1

        try:
            # extract SIZE from ".local/share/icons/SIZExSIZE/..."
            result = number_extractor.search(name)

            if result:
                group = result.group(0)

                if group:
                    size = int(group)
        except BaseException as e:
            logging.warning(
                'list_user_icon_dirs(): could not extract icon size from "%s": %s',
                name, str(e))
            size = -1

        dirs.append((size, name))

    return sorted(dirs, key=lambda i: i[0], reverse=True)


def detect_current_icon_theme_name():
    try:
        gsettings = Gio.Settings.new('org.gnome.desktop.interface')
        return gsettings.get_value('icon-theme').get_string()
    except BaseException as e:
        logging.warning('Could not determine the name of the current icon theme: %s',
                        str(e))
        return None


# Turns icon names into actual filenames. Returns tuples of (filename,
# path indicator), where path indicator is True if the icon name originally
# was a full path+filename to the icon and not just an icon name.
# This information is needed when we create desktop and panel links.
# This class does not even try to duplicate the full icon searching algorithm
# documented at https://specifications.freedesktop.org/icon-theme-spec/icon-
# theme-spec-latest.html, but instead does something that suits our needs.
# It creates a list of zero or more subdirectories under the specified
# theme "root" directory and sorts them by icon size. When an icon is requested,
# these directories are scanned to find the matching icon. You can specify
# a preferred pixel size and if an icon of that exact size exists, it will be
# returned. Otherwise, the biggest matching icon is returned (it can be an
# SVG file). Future work includes optional support for theme.index cache
# files (I briefly looked at them but haven't written a parser for them yet).
class IconLocator:
    # Icon size limits. Too large icons are slow to load, but too small will
    # be too blurry. The highest we accept is 64x64, but set the maximum size
    # to 65 and use it for SVG images to prioritize them.
    MAX_ACCEPTED_SIZE = 65
    MIN_ACCEPTED_SIZE = 24

    # Avoid too deep recursive scans. We follow symlinks, so things can go
    # badly wrong.
    MAX_SCAN_DEPTH = 5

    # Some icon themes contain all sorts of stuff we don't care about. We want
    # programs to use program icons, not emojis. So we skip all directories
    # that are on this list.
    IGNORE_LIST = frozenset([
        'actions', 'animations', 'applets', 'emblems', 'categories',
        'emotes'
    ])

    ICON_EXTENSIONS = ('.svg', '.svgz', '.png', '.xpm', '.jpg', '.jpeg')

    number_extractor = re.compile(r'\d+')


    # Recursively scans directories for possible icon search directories
    def __scanner(self, level, directory, out):
        if level > self.MAX_SCAN_DEPTH:
            return

        # Find subdirectories in this directory
        subdirs = []

        try:
            for d in os.scandir(directory):
                if not d.is_dir() or '@' in d.name:
                    continue

                if d.name in self.IGNORE_LIST:
                    continue

                full_path = os.path.join(directory, d.name)

                # Store this directory for later recursal
                subdirs.append((d.name, full_path))

                # Then update the actual icon paths list. If the path
                # contains a number (ie. an icon size), find that number.
                size = self.number_extractor.search(full_path)

                if size:
                    try:
                        size = int(size.group(0), 10)
                    except:
                        continue
                elif 'scalable' in full_path:
                    # Prioritize SVG (scalable) directories
                    size = self.MAX_ACCEPTED_SIZE
                else:
                    continue

                # If the size is good, accept it as a possible icon
                # search path
                if self.MIN_ACCEPTED_SIZE <= size <= self.MAX_ACCEPTED_SIZE:
                    out.append((size, full_path))

        except BaseException as e:
            logging.error('Unable to scan directory "%s": %s',
                          directory, str(e))
            return

        # Precache apps directories
        if 'apps' in directory:
            self.__cache_directory_contents(directory)

        # Recurse
        for d in subdirs:
            self.__scanner(level + 1, d[1], out)


    def __sorter(self, item):
        # If this is an "applications" directory, prioritize it higher, even
        # higher than non-application scalable directories. This way we check
        # all apps directories (of all sizes) first.
        if 'apps' in item[1]:
            return item[0] * 99999

        # Otherwise just sort by icon pixel size
        return item[0]


    # Lists and caches the filenames in the given directory
    def __cache_directory_contents(self, path):
        names = []

        try:
            with os.scandir(path) as it:
                for d in it:
                    if not d.is_dir():
                        names.append(d.name)
        except BaseException as e:
            logging.warning('Could not scan directory "%s": %s',
                            path, str(e))
            names = []

        self.dircache[path] = frozenset(names)


    def __init__(self):
        # What we scan
        self.theme_base_dirs = []
        self.generic_dirs = []

        # Where the output of the scan is stored
        self.theme_dirs = []

        # Lookup caches
        self.cache = {}
        self.dircache = {}


    def set_generic_dirs(self, generic_dirs):
        self.generic_dirs = generic_dirs


    def set_theme_base_dirs(self, theme_base_dirs):
        if isinstance(theme_base_dirs, list):
            self.theme_base_dirs = theme_base_dirs
        else:
            self.theme_base_dirs = [theme_base_dirs]


    def clear(self):
        self.theme_dirs = []
        self.cache = {}


    def scan_directories(self):
        self.clear()

        # Scan each theme directory
        for d in self.theme_base_dirs:
            out = []
            logging.info('IconLocator::scan_directories(): scanning "%s"', d)
            self.__scanner(1, d, out)
            self.theme_dirs += out

        # Sort the directories
        self.theme_dirs = sorted(self.theme_dirs, key=self.__sorter, reverse=True)


    def locate_icon(self, name, preferred_size=-1):
        if name is None:
            return (None, False)

        # Already cached?
        if name in self.cache:
            return self.cache[name]

        # If the icon name is already a full path, use it as-is
        if os.path.isfile(name):
            self.cache[name] = (name, True)
            return (name, True)

        # ----------------------------------------------------------------------

        def __check_dir(directory, name):
            if directory not in self.dircache:
                self.__cache_directory_contents(directory)

            # Try the name as-is first (some icon names are just "name.ext"
            # without a path)
            candidate = os.path.join(directory, name)

            if os.path.isfile(candidate):
                return candidate

            names = self.dircache[directory]

            if name in names:
                return os.path.join(directory, name)

            # Try the different file extensions
            for ext in self.ICON_EXTENSIONS:
                candidate = name + ext

                if candidate in names:
                    return os.path.join(directory, name + ext)

            return None

        # ----------------------------------------------------------------------
        # First check the theme directories for exact size matches

        if preferred_size != -1:
            for th_dir in self.theme_dirs:
                if th_dir[0] != preferred_size:
                    continue

                candidate = __check_dir(th_dir[1], name)

                if candidate:
                    self.cache[name] = (candidate, False)
                    return (candidate, False)

        # ----------------------------------------------------------------------
        # An exact size match was not found. Check the other theme
        # directories.

        for th_dir in self.theme_dirs:
            if th_dir[0] == preferred_size:
                continue

            candidate = __check_dir(th_dir[1], name)

            if candidate:
                self.cache[name] = (candidate, False)
                return (candidate, False)

        # ----------------------------------------------------------------------
        # Finally check the generic directories

        for gen_dir in self.generic_dirs:
            candidate = __check_dir(gen_dir, name)

            if candidate:
                self.cache[name] = (candidate, False)
                return (candidate, False)

        # ----------------------------------------------------------------------
        # Nothing found

        self.cache[name] = (None, False)
        return (None, False)
