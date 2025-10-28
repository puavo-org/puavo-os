# Common utility stuff

import gi

gi.require_version('Gtk', '4.0')
from gi.repository import Gtk

from logger import log


def show_error_message(parent, message, secondary_message=None):
    """Show a modal error message box."""

    dialog = Gtk.MessageDialog(parent=parent,
                               modal=True,
                               destroy_with_parent=True,
                               message_type=Gtk.MessageType.ERROR,
                               buttons=Gtk.ButtonsType.OK,
                               text=message)

    # XXX this is not modal like it used to be, should it be?
    if secondary_message:
        secondary_label = Gtk.Label(label=secondary_message)
        secondary_label.set_use_markup(True)
        secondary_label.set_wrap(True)
        content_area = dialog.get_message_area()
        content_area.append(secondary_label)

    dialog.connect('response', lambda d, r: d.destroy())
    dialog.present()


def show_info_message(parent, message, secondary_message=None):
    """Show a modal information message box."""

    dialog = Gtk.MessageDialog(parent=parent,
                               modal=True,
                               destroy_with_parent=True,
                               message_type=Gtk.MessageType.INFO,
                               buttons=Gtk.ButtonsType.OK,
                               text=message)

    if secondary_message:
        dialog.format_secondary_markup(secondary_message)

    dialog.run()
    dialog.hide()
