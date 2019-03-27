# Efficiently (?) caches small icons using larger bitmaps

import math

from collections import OrderedDict
import logging
import cairo

from utils_gui import load_image_at_size, draw_x


class Icon:
    """A handle to a cached icon."""
    def __init__(self):
        self.index = None
        self.usable = False
        self.size = 0
        self.filename = ""      # needed when creating desktop/panel icons


class IconCache:
    class CacheSlot:
        def __init__(self, x, y):
            self.x = x
            self.y = y
            self.icon = None        # the actual Icon instance, or None

    def __init__(self,
                 icon_size,
                 bitmap_size=1024):

        """Initializes an icon cache. icon_size is the size of a single
        icon (width and height), and bitmap_size is the dimensions of
        the atlas."""

        # Too small bitmap size makes the cache unusable (creates too
        # many atlas bitmaps), but larger ones only waste memory
        if bitmap_size < 128 or bitmap_size > 2048:
            raise RuntimeError('Icon cache surface dimensions must be '
                               'between 128 and 2048; {0} is not valid.'.
                               format(bitmap_size))

        self.__icon_size = icon_size
        self.__bitmap_size = bitmap_size

        # Filename -> icon lookup. The map value is an index to self.__icons.
        self.__filename_lookup = OrderedDict()

        self.__create_slots()
        self.__create_atlas()


    def __create_slots(self):
        # Create storage for the icons. Each of these "slots" stores
        # one icon. The icons store their index to self.__icons array.
        max_icons = math.floor(self.__bitmap_size / self.__icon_size)
        self.__icons = []

        for y in range(0, max_icons):
            ypos = y * self.__icon_size

            for x in range(0, max_icons):
                self.__icons.append(self.CacheSlot(x * self.__icon_size, ypos))


    def __create_atlas(self):
        # Create the actual atlas image
        self.__atlas_surface = cairo.ImageSurface(
            cairo.FORMAT_ARGB32,
            self.__bitmap_size,
            self.__bitmap_size)

        self.__atlas_context = cairo.Context(self.__atlas_surface)

        # Fill the atlas image with nothingness (even the alpha channel) so
        # we can blit from it without messing up whatever's already behind
        # the icon
        self.__atlas_context.save()
        self.__atlas_context.set_source_rgba(0.0, 0.0, 0.0, 0.0)
        self.__atlas_context.set_operator(cairo.OPERATOR_SOURCE)
        self.__atlas_context.rectangle(0, 0, self.__bitmap_size, self.__bitmap_size)
        self.__atlas_context.paint()
        self.__atlas_context.restore()


    def load_icon(self, path):
        """Loads an icon. Returns a handle to a cached icon if the icon
        has been loaded already, otherwise loads the image from disk.
        Will ALWAYS return a valid icon handle you can use, even if the
        handle points to a missing icon."""

        # Already loaded?
        if path in self.__filename_lookup:
            return self.__icons[self.__filename_lookup[path]].icon

        # Load a new icon. Find the next free cache slot.
        index = None

        for (n, s) in enumerate(self.__icons):
            if s.icon is None:
                index = n
                break

        if index is None:
            raise RuntimeError('the icon cache is full')

        # There's still room for this icon
        new_icon = Icon()

        new_icon.index = index
        new_icon.size = self.__icon_size
        new_icon.filename = path

        slot = self.__icons[index]

        # Try to load the actual icon image. If it succeeds, draw it onto the
        # atlas bitmap.
        try:
            icon_surface = load_image_at_size(
                path, self.__icon_size, self.__icon_size)

            self.__atlas_context.set_source_surface(icon_surface, slot.x, slot.y)
            self.__atlas_context.paint()

            new_icon.usable = True
        except Exception as e:
            msg = str(e)

            if msg == '':
                # this actually has happened
                msg = '<The exception has no message>'

            logging.error('Could not load icon "%s": %s', path, msg)

        # Regardless of what happened above, we now have a new icon. Store it.
        slot.icon = new_icon
        self.__filename_lookup[path] = index

        return new_icon


    def __getitem__(self, path):
        """Overload [] for easier access."""

        return self.load_icon(path)


    def is_loaded(self, path):
        """Checks if this icon has been cached already."""

        return path in self.__filename_lookup


    def draw_icon(self, ctx, icon, x, y):
        """Draws the icon onto the Cairo context at the specified
        coordinates."""

        if (not isinstance(icon, Icon)) or \
                (not icon.usable) or \
                (icon.size != self.__icon_size) or \
                (icon.index < 0) or (icon.index > len(self.__icons) - 1):
            draw_x(ctx, x, y, self.__icon_size, self.__icon_size)
        else:
            slot = self.__icons[icon.index]

            # https://www.cairographics.org/FAQ/#paint_from_a_surface
            ctx.set_source_surface(self.__atlas_surface, x - slot.x, y - slot.y)
            ctx.rectangle(x, y, self.__icon_size, self.__icon_size)
            ctx.fill()


    def clear(self):
        """Completely clears the cache."""

        self.__filename_lookup = OrderedDict()
        self.__create_slots()
        self.__create_atlas()


    def stats(self):
        return (len(self.__filename_lookup), len(self.__icons))


# Instantiate global caches for program/menu buttons and
# sidebar buttons
ICONS32 = IconCache(32, 128)
ICONS48 = IconCache(48, 48 * 15)
