# Common utility stuff

import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk


def show_error_message(parent, message, secondary_message=None):
    """Show a modal error message box."""

    dialog = Gtk.MessageDialog(parent=parent,
                               modal=True,
                               destroy_with_parent=True,
                               message_type=Gtk.MessageType.ERROR,
                               buttons=Gtk.ButtonsType.OK,
                               text=message)

    if secondary_message:
        dialog.format_secondary_markup(secondary_message)

    dialog.run()
    dialog.hide()


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
