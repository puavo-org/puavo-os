# Efficiently (?) caches small icons using larger bitmaps

from collections import OrderedDict
import logging
import cairo

from utils_gui import load_image_at_size, draw_x


class Icon:
    """A handle to a cached icon."""
    def __init__(self):
        self.file_name = ""
        self.usable = False
        self.size = 0
        self.atlas = -1
        self.x = 0
        self.y = 0


class IconCache:
    """Efficiently caches multiple small icons in larger atlases."""

    STATE_OK = 0
    STATE_FAILED = 1
    STATE_UNKNOWN = 2

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

        # Filename -> icon lookup
        self.__lookup = OrderedDict()

        # List of (ImageSurface, Context) tuples
        self.__atlas = []

        # The current atlas
        self.__atlas_num = -1

        # X and Y position for the next icon
        self.__x = 0
        self.__y = 0

        self.__create_atlas()


    def __create_atlas(self):
        """Creates another atlas surface."""

        surface = cairo.ImageSurface(
            cairo.FORMAT_ARGB32,
            self.__bitmap_size,
            self.__bitmap_size)
        context = cairo.Context(surface)

        # Fill the surface with nothingness (even the alpha channel) so
        # we can blit from it without messing up whatever's already behind
        # the icon
        context.save()
        context.set_source_rgba(0.0, 0.0, 0.0, 0.0)
        context.set_operator(cairo.OPERATOR_SOURCE)
        context.rectangle(0, 0, self.__bitmap_size, self.__bitmap_size)
        context.paint()
        context.restore()

        self.__atlas.append((surface, context))
        self.__atlas_num += 1
        self.__x = 0
        self.__y = 0


    def is_loaded(self, path):
        """Checks if this icon has been cached already. Does not
        actually cache it!"""

        return path in self.__lookup


    def load_icon(self, path):
        """Loads an icon. Returns a handle to a cached icon if the icon
        has been loaded already, otherwise loads the image from disk.
        Will ALWAYS return a valid icon handle you can use, even if the
        handle points to a missing icon."""

        # Already loaded?
        if path in self.__lookup:
            return self.__lookup[path]

        # Load a new icon
        icon = Icon()

        icon.file_name = path
        icon.size = self.__icon_size
        icon.atlas = self.__atlas_num
        icon.x = self.__x
        icon.y = self.__y

        try:
            icon_surface = load_image_at_size(
                path, self.__icon_size, self.__icon_size)

            if (self.__y + self.__icon_size) > self.__bitmap_size:
                # This atlas is full, create another
                self.__create_atlas()
                logging.info('Created a new icon cache atlas for size %d',
                             self.__icon_size)

                icon.atlas = self.__atlas_num
                icon.x = self.__x
                icon.y = self.__y

            # Draw the icon onto the current atlas surface
            ctx = self.__atlas[self.__atlas_num][1]
            ctx.set_source_surface(icon_surface, self.__x, self.__y)
            ctx.paint()

            icon.usable = True
        except Exception as e:
            msg = str(e)

            if msg == '':
                # this actually has happened
                msg = '<The exception has no message>'

            logging.error('Could not load icon "%s": %s', path, msg)
            icon.usable = False

        # Compute the position for the next icon (always done)
        self.__x += self.__icon_size

        if (self.__x + self.__icon_size) > self.__bitmap_size:
            self.__x = 0
            self.__y += self.__icon_size

        self.__lookup[path] = icon
        return icon


    def __getitem__(self, path):
        """Overload [] for easier access."""

        return self.load_icon(path)


    def clear(self):
        """Completely clears the cache."""

        self.__lookup = OrderedDict()
        self.__atlas = []
        self.__atlas_num = -1
        self.__x = 0
        self.__y = 0
        self.__create_atlas()


    def draw_icon(self, ctx, icon, x, y):
        """Draws the icon onto the Cairo context at the specified
        coordinates."""

        if (not isinstance(icon, Icon)) or \
                (not icon.usable) or \
                (icon.size != self.__icon_size) or \
                (icon.atlas < 0) or \
                (icon.atlas > len(self.__atlas) - 1):
            draw_x(ctx, x, y, self.__icon_size, self.__icon_size)
        else:
            # https://www.cairographics.org/FAQ/#paint_from_a_surface
            ctx.set_source_surface(
                self.__atlas[icon.atlas][0], x - icon.x, y - icon.y)
            ctx.rectangle(x, y, self.__icon_size, self.__icon_size)
            ctx.fill()


    def stats(self):
        return {
            'num_atlases': self.__atlas_num + 1,
            'num_icons': len(self.__lookup),
            'capacity': (self.__bitmap_size / self.__icon_size) ** 2
        }


# Instantiate global caches for program/menu buttons and
# sidebar buttons
ICONS32 = IconCache(32, 128)
ICONS48 = IconCache(48, 48 * 15)
