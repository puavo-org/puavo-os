# PuavoMenu miscellaneous utility functions

from math import radians
from logger import error as log_error, warn as log_warn


def localize(where, lang_id):
    """Given a string/list/dict and a key, looks up a localized string
    using the key."""

    if where is None:
        log_error('localize(): "where" is None, nothing to localize!')
        return '[ERROR]'

    if isinstance(where, str):
        # just one string, nothing to localize, use it as-is
        return where
    elif isinstance(where, list):
        # a list of dicts, merge them
        where = {k: v for p in where for k, v in p.items()}

    if lang_id in where:
        # have a localized string, use it
        return str(where[lang_id])

    if 'en' in where:
        # no localized string available; try English, it's the default
        return str(where['en'])

    # it's a list with only one entry and it's not the language
    # we want, but we have to use it anyway
    log_warn('localize(): missing localization for "{0}" in "{1}"'.
             format(lang_id, where))

    return str(where[list(where)[0]])


def get_file_contents(name, default=''):
    """Reads the contents of a UTF-8 file into a buffer."""

    try:
        return open(name, 'r', encoding='utf-8').read().strip()
    except Exception as e:
        log_error('Could not load file "{0}": {1}'.format(name, e))
        return default


def expand_variables(string, variables=None):
    """Expands "$(name)" variables in a string."""

    if not isinstance(string, str):
        return string

    if not isinstance(variables, dict):
        return string

    start = 0
    out = ''

    while True:
        # find the next token start
        pos = string.find('$(', start)

        if pos == -1:
            # no more tokens, copy the remainder
            out += string[start:]
            break

        # find the token end
        end = string.find(')', pos + 2)

        if end == -1:
            # not found, copy as-is
            out += string[start:]
            break

        out += string[start:pos]

        # expand the token if possible
        token = string[pos+2:end]

        if len(token) == 0 or token not in variables:
            out += string[pos:end+1]
        else:
            out += variables[token]

        start = end + 1

    return out


def load_image_at_size(name, width, height):
    """Loads an image file at the specified size. Does NOT handle
    exceptions!"""

    from gi.repository import GdkPixbuf, Gdk
    from cairo import ImageSurface, FORMAT_ARGB32, Context

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
