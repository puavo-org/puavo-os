# Utility functions that need Gtk, ie. GUI stuff

from math import radians

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk, GdkPixbuf, Gdk
import cairo


def load_image_at_size(name, width, height):
    """Loads an image file at the specified size. Does NOT handle
    exceptions!"""

    pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(name, width, height)
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
    ctx = cairo.Context(surface)
    Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 0, 0)
    ctx.paint()

    return surface


def rounded_rectangle(ctx, x, y, width, height, radius=20):
    """Creates a path with rounded corners. You must stroke/fill
    the path yourself."""

    # make the arc()'s work correctly
    ctx.move_to(x, y)

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


def create_desktop_link(filename, program):
    """Adds program (an instance of Program class) to the desktop. Moved
    here from main.py. Make sure you handle exceptions if you call this!"""

    from constants import PROGRAM_TYPE_DESKTOP, \
                          PROGRAM_TYPE_CUSTOM, \
                          PROGRAM_TYPE_WEB

    with open(filename, 'w', encoding='utf-8') as out:
        if program.program_type != PROGRAM_TYPE_WEB:
            out.write('#!/usr/bin/env xdg-open\n')

        out.write('[Desktop Entry]\n')
        out.write('Encoding=UTF-8\n')
        out.write('Version=1.0\n')
        out.write('Name={0}\n'.format(program.name))

        if program.program_type in (PROGRAM_TYPE_DESKTOP, PROGRAM_TYPE_CUSTOM):
            out.write('Type=Application\n')
            out.write('Exec={0}\n'.format(program.command))
        else:
            out.write('Type=Link\n')
            out.write('URL={0}\n'.format(program.command))

        if program.icon:
            out.write('Icon={0}\n'.format(program.icon.filename))
        else:
            if program.program_type == PROGRAM_TYPE_WEB:
                # a "generic" web icon
                out.write('Icon=text-html\n')

    if program.program_type != PROGRAM_TYPE_WEB:
        # Make the file runnable, or GNOME won't accept it
        from os import chmod
        import subprocess

        chmod(filename, 0o755)

        # Mark the file as trusted (I hate you GNOME)
        subprocess.Popen(['gvfs-set-attribute', filename,
                          'metadata::trusted', 'yes'],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)


def create_panel_link(program):
    """Adds a program to the bottom panel. Moved here from main.py. Remember
    to handle exceptions if you call this!"""

    from gi.repository import GLib, Gio
    import logging

    if program.original_desktop_file:
        desktop_name = program.original_desktop_file
    else:
        desktop_name = program.name + '.desktop'

    logging.debug('Desktop file name is "%s"', desktop_name)

    SCHEMA = 'org.gnome.shell'
    KEY = 'favorite-apps'

    # Is the program already in the panel?
    gsettings = Gio.Settings.new(SCHEMA)
    panel_faves = gsettings.get_value(KEY).unpack()

    if desktop_name in panel_faves:
        logging.info('Desktop file "%s" is already in the panel, ' \
                     'doing nothing', desktop_name)
        return

    if not program.original_desktop_file:
        # Not all programs have a .desktop file, so we have to
        # create it manually.
        from os import environ
        from os.path import join as path_join
        from constants import PROGRAM_TYPE_WEB

        name = path_join(environ['HOME'],
                         '.local',
                         'share',
                         'applications',
                         desktop_name)

        logging.debug('Creating a local .desktop file for "%s", '
                      'name="%s"', program.name, name)

        with open(name, 'w', encoding='utf-8') as out:
            out.write('[Desktop Entry]\n')
            out.write('Encoding=UTF-8\n')
            out.write('Version=1.0\n')
            out.write('Name={0}\n'.format(program.name))
            out.write('Type=Application\n')

            if program.program_type == PROGRAM_TYPE_WEB:
                # GNOME, in its infinite wisdom, has decided that "you shall
                # not have web links in the panel" and then broke the "Link"
                # type icons. So let's hope that xdg-open can open the URL in
                # whatever browser is the default browser.
                # This *WILL* fail one day with some really weird URLs...
                out.write('Exec=xdg-open "{0}"\n'.format(program.command))
            else:
                out.write('Exec={0}\n'.format(program.command))

            if program.icon:
                out.write('Icon={0}\n'.format(program.icon.filename))
            else:
                if program.program_type == PROGRAM_TYPE_WEB:
                    # a "generic" web icon
                    out.write('Icon=text-html\n')

    # Add the new .desktop file to the list
    panel_faves.append(desktop_name)
    gsettings.set_value(KEY, GLib.Variant.new_strv(panel_faves))
    logging.info('Panel icon created')
