# Base class for various custom buttons

import logging

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
gi.require_version('PangoCairo', '1.0')
from gi.repository import Gtk, Pango, PangoCairo

import utils_gui


# A general-purpose clickable button that displays an icon and a
# label. Reacts to mouse enter and leave events, highlighting the
# whole button area. Can optionally also display a tooltip text.
# This is a base class that does not do much. You MUST derive child
# class/-es that compute element sizes and positions if you want to
# use this!
class HoverIconButtonBase(Gtk.Button):
    def __init__(self,
                 parent,
                 settings,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None):

        super().__init__()

        # Setup signals
        self.connect('enter-notify-event', self.on_mouse_enter)
        self.connect('leave-notify-event', self.on_mouse_leave)
        self.connect('draw', self.on_draw)

        (width, height) = self.get_preferred_button_size()
        self.set_size_request(width, height)

        self.parent = parent
        self.label = label

        # The icon is a tuple containing a handle to the icon cache
        # and an icon index.
        if not isinstance(icon, tuple) or len(icon) != 2 or \
           icon[0] is None or icon[1] is None:
            self.icon_cache = None
            self.icon_handle = None
        else:
            self.icon_cache = icon[0]
            self.icon_handle = icon[1]

        if tooltip:
            self.set_property('tooltip-text', tooltip)

        self.data = data

        self.get_style_context().add_class('pm_button')

        # Not disabled by default
        self.disabled = False

        # For rendering the label
        self.label_layout = self.create_pango_layout(label)
        self.label_layout.set_alignment(Pango.Alignment.CENTER)
        self.label_layout.set_wrap(Pango.WrapMode.WORD_CHAR)
        self.label_layout.set_width((width - 20) * Pango.SCALE)

        # Hover state
        self.hover = False

        # Set these in derived classes to control the look
        self.icon_size = -1
        self.icon_pos = [-1, -1]
        self.label_pos = [-1, -1]

        self.compute_elements()


    def add_style_class(self, clazz):
        self.get_style_context().add_class(clazz)


    def get_preferred_button_size(self):
        # Implement this in derived classes
        pass


    def compute_elements(self):
        # Implement this in derived classes
        pass


    # Mouse enters the button area
    def on_mouse_enter(self, widget, event):
        if not self.disabled:
            self.hover = True

        return False


    # Mouse leaves the button area
    def on_mouse_leave(self, widget, event):
        self.hover = False
        return False


    # Draw the button
    def on_draw(self, widget, ctx):
        try:
            rect = self.get_allocation()

            # setup the main clipping rectangle
            ctx.rectangle(0, 0, rect.width, rect.height)
            ctx.clip()

            self.draw_background(ctx, rect)
            self.draw_icon(ctx)
            self.draw_label(ctx)
        except Exception as exception:
            logging.error('Could not draw a HoverIconButton widget: %s',
                          str(exception))

        # return True to prevent default event processing
        return True


    # Draw the button background
    def draw_background(self, ctx, rect):
        style = self.get_style_context()
        Gtk.render_background(style, ctx, 0.0, 0.0, rect.width, rect.height)
        Gtk.render_frame(style, ctx, 0.0, 0.0, rect.width, rect.height)


    # Draw the icon
    def draw_icon(self, ctx):
        if self.icon_cache:
            self.icon_cache.draw_icon(self.icon_handle,
                                      ctx,
                                      self.icon_pos[0], self.icon_pos[1])
        else:
            utils_gui.draw_x(ctx,
                             self.icon_pos[0], self.icon_pos[1],
                             self.icon_size, self.icon_size)


    # Draw the label
    def draw_label(self, ctx):
        Gtk.render_layout(self.get_style_context(), ctx,
                          self.label_pos[0], self.label_pos[1],
                          self.label_layout)


    # It's possible to disable buttons, but because it's so rare
    # occurrence, you cannot set the flag in the constructor.
    # Instead, you must call this method. At the moment, a button
    # that gets disabled cannot be re-enabled.
    def disable(self):
        self.set_sensitive(False)
        self.disabled = True
