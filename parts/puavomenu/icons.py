# Utility classes for locating and storing hundreds of icons efficiently.

import os
import logging
import utils_gui

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
import cairo


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
        return (atlas << 16) | (y << 8) | x


    # Extracts icon location from a 24-bit integer
    def unpack_index(self, index):
        try:
            return (index >> 16, (index >> 8) & 0xFF, index & 0xFF)
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
            if len(self.atlases) > 0:
                self.atlases[-1].full = True

            self.atlases.append(Atlas(self.grid_size, self.grid_size, self.bitmap_size))

            # Start from the upper left corner
            atlas_num = len(self.atlases) - 1
            cell_y = 0
            cell_x = 0
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
            return

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


# Turns icon names into actual filenames. Returns tuples of (filename,
# path indicator), where path indicator is True if the icon name originally
# was a full path+filename to the icon and not just an icon name.
# This information is needed when we create desktop and panel links.
class IconLocator:
    def __init__(self, icon_dirs):
        self.icon_dirs = icon_dirs

        # Multiple programs can use the same generic icon name. The IconCache
        # class keeps track of filenames, so it won't load the same file more
        # than once. But that won't work with generic icon names, so another
        # layer of caching is used for them.
        self.generic_cache = {}


    def set_directories(self, icon_dirs):
        self.icon_dirs = icon_dirs


    def clear_cache(self):
        self.generic_cache = {}


    # Searches the filesystem for the icon
    def locate(self, icon_name):
        if icon_name is None:
            # No icon defined at all. This is an error, but it does happen.
            return (None, False)

        # Is the icon name a full path to an image file, or just
        # a generic name?
        _, ext = os.path.splitext(icon_name)
        icon_name_is_path = ext in ICON_EXTENSIONS

        # Cache generic icon names, so we have to search for them only once
        if (not icon_name_is_path) and (icon_name in self.generic_cache):
            # Reuse a cached generic icon
            icon_name = self.generic_cache[icon_name]
            icon_name_is_path = True

        # ----------------------------------------------------------------------
        # The easiest case: it's a full path + name to an image file

        if icon_name_is_path:
            if os.path.isfile(icon_name):
                return (icon_name, True)

        # An icon file was specified, but it could not be loaded. Sometimes
        # icon names contain an extension (ie. "name.png") that confuses our
        # autodetection. Unless the icon name really is a full path + filename,
        # try to locate the correct image.
        if len(os.path.dirname(icon_name)) > 0:
            return (None, False)

        # ----------------------------------------------------------------------
        # The icon is a generic icon. Try to locate the matching file.

        icon_path = None

        for dir_name in self.icon_dirs:
            # Try the name as-is first (some icon names are just "name.ext"
            # without a path)
            candidate = os.path.join(dir_name, icon_name)

            if os.path.isfile(candidate):
                return (candidate, True)

            # Try the different file extensions
            for ext in ICON_EXTENSIONS:
                candidate = os.path.join(dir_name, icon_name + ext)

                if os.path.isfile(candidate):
                    icon_path = candidate
                    break

            if icon_path:
                break

        if not icon_path:
            # The icon simply could not be found
            return (None, False)

        if not icon_name_is_path:
            # Cache the icon file name, so we don't have to repeatedly
            # search the filesystem
            self.generic_cache[icon_name] = icon_path

        return (icon_path, icon_name_is_path)
