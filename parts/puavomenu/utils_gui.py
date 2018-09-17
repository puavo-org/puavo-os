# Utility functions that need Gtk, ie. GUI stuff

from math import radians

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk, GdkPixbuf, Gdk
from cairo import ImageSurface, FORMAT_ARGB32, Context


def load_image_at_size(name, width, height):
    """Loads an image file at the specified size. Does NOT handle
    exceptions!"""

    pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(name, width, height)
    surface = ImageSurface(FORMAT_ARGB32, width, height)
    ctx = Context(surface)
    Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 0, 0)
    ctx.paint()

    return surface


def rounded_rectangle(ctx, x, y, width, height, radius=20):
    """Creates a path with rounded corners. You must stroke/fill
    the path yourself."""

    # 2 is the smallest radius that actually is visible.
    # Determined empirically.
    if radius < 2:
        ctx.rectangle(x, y, width, height)
        return

    # see https://www.cairographics.org/samples/rounded_rectangle/
    ctx.arc(x + width - radius, y + radius, radius,
            radians(-90.0), radians(0.0))
    ctx.arc(x + width - radius, y + height - radius, radius,
            radians(0.0), radians(90.0))
    ctx.arc(x + radius, y + height - radius, radius,
            radians(90.0), radians(180.0))
    ctx.arc(x + radius, y + radius, radius,
            radians(180.0), radians(270.0))


def draw_x(ctx, x, y, width, height, color=None):
    """Draws an arbitrarily-sized "X" placeholder icon."""

    color = color or [1.0, 0.0, 0.0]

    # https://www.cairographics.org/FAQ/#sharp_lines
    ctx.save()
    ctx.set_source_rgba(1.0, 1.0, 1.0, 1.0)
    ctx.rectangle(x + 0.5, y + 0.5, width - 1.0, height - 1.0)
    ctx.fill_preserve()
    ctx.set_source_rgba(color[0], color[1], color[2], 1.0)
    ctx.move_to(x + 0.5, y + 0.5)
    ctx.line_to(x + width - 0.5, y + height - 0.5)
    ctx.move_to(x + 0.5, y + height - 0.5)
    ctx.line_to(x + width - 0.5, y + 0.5)
    ctx.set_line_width(1)
    ctx.stroke()
    ctx.restore()


def create_separator(container, x, y, w, h, orientation):
    sep = Gtk.Separator(orientation=orientation)
    sep.set_size_request(w, h)
    container.put(sep, x, y)
    sep.show()

