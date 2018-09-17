# Utility functions that need Gtk, ie. GUI stuff

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk

def create_separator(container, x, y, w, h, orientation):
    sep = Gtk.Separator(orientation=orientation)
    sep.set_size_request(w, h)
    container.put(sep, x, y)
    sep.show()

