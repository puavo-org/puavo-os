# Custom program button class

import logging
import math

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk, Gdk

from constants import PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT, \
                      PROGRAM_BUTTON_ICON_SIZE
import utils
import utils_gui
from strings import STRINGS

import buttons.base
import menudata


class ProgramButton(buttons.base.HoverIconButtonBase):
    # Dimensions and positioning for the hover indicator box
    INDICATOR_WIDTH = 20
    INDICATOR_HEIGHT = 30
    INDICATOR_EDGE = 5
    INDICATOR_ARROW_SIZE = 5
    INDICATOR_DOT_RADIUS = 2
    INDICATOR_DOT_SPACING = 5.0


    def __init__(self,
                 parent,
                 settings,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 is_fave=False,
                 enable_popup=True):

        super().__init__(parent,
                         settings,
                         label,
                         icon,
                         tooltip,
                         data)

        self.add_style_class('button_program')

        self.is_fave = is_fave

        if is_fave:
            # permit additional styles
            self.add_style_class('frequent_button')

        # Need this for localize()
        self.__language = settings.language

        if settings.desktop_dir is None:
            self.__have_desktop_dir = False
        else:
            self.__have_desktop_dir = True

        # Setup the popup menu
        self.__enable_popup = enable_popup
        self.__popup_hover = False
        self.__popup_open = False
        self.__hover_signal = None

        # Extra handling for puavo-pkg program installer buttons
        self.__is_installer = False

        if isinstance(self.data, menudata.PuavoPkgProgram) and self.data.is_installer():
            self.__is_installer = True

        if self.__is_installer:
            self.add_style_class('installer')

            # No popup menus for installers, they are not going to work
            # from the panel or the desktop...
            self.__enable_popup = False

            # Append an installer identifier to the name
            title = utils.localize(STRINGS['button_puavopkg_installer_suffix'],
                                   settings.language)
            markup = '%s\n<small><i>[%s]</i></small>' % (label, title)
            self.label_layout.set_markup(markup)

            self.set_property('tooltip-text',
                              utils.localize(STRINGS['button_puavopkg_installer_tooltip'],
                                             settings.language))

        self.__menu = None
        self.__menu_signal = self.connect('button-press-event',
                                          self.open_menu)

        # We want mouse motion events
        self.set_events(self.get_events() | Gdk.EventMask.POINTER_MOTION_MASK)

        # Setup the popup indicator box. Compute its coordinates.
        self.__indicator_x1 = PROGRAM_BUTTON_WIDTH - self.INDICATOR_WIDTH - self.INDICATOR_EDGE
        self.__indicator_x2 = self.__indicator_x1 + self.INDICATOR_WIDTH
        self.__indicator_y1 = self.INDICATOR_EDGE
        self.__indicator_y2 = self.__indicator_y1 + self.INDICATOR_HEIGHT


    def get_preferred_button_size(self):
        return (PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT)


    def compute_elements(self):
        self.corner_rounding = 5

        self.icon_size = PROGRAM_BUTTON_ICON_SIZE

        self.icon_pos = [
            (PROGRAM_BUTTON_WIDTH / 2) - (PROGRAM_BUTTON_ICON_SIZE / 2),
            20
        ]

        # Center the text horizontally
        self.label_pos = [
            10,  # left padding
            20 + PROGRAM_BUTTON_ICON_SIZE + 5
        ]


    # Mouse enters the button area
    def on_mouse_enter(self, widget, event):
        if not self.disabled:
            self.hover = True

            if self.__enable_popup:
                # Start tracking mouse movements inside the button
                self.__hover_signal = \
                    self.connect('motion-notify-event', self.__on_mouse_hover_move)

        return False


    # Mouse leaves the button area
    def on_mouse_leave(self, widget, event):
        if not self.disabled:
            self.hover = False

            if self.__hover_signal:
                # Stop tracking mouse movements
                self.disconnect(self.__hover_signal)
                self.__hover_signal = None

        return False


    # Track mouse movements and update the hover indicator box
    def __on_mouse_hover_move(self, widget, event):
        if not self.disabled:
            (window, mouse_x, mouse_y, state) = event.window.get_pointer()
            self.__hover_check(mouse_x, mouse_y)

        return False


    def __hover_check(self, mouse_x, mouse_y):
        new_state = (mouse_x >= self.__indicator_x1) and \
                    (mouse_x <= self.__indicator_x2) and \
                    (mouse_y >= self.__indicator_y1) and \
                    (mouse_y <= self.__indicator_y2)

        if new_state != self.__popup_hover:
            # Only redraw when the hover state actually changes
            self.__popup_hover = new_state
            self.queue_draw()


    def on_draw(self, widget, ctx):
        try:
            rect = self.get_allocation()

            # I don't want to copy-paste draw_background() and draw_label()
            # from the base class there, so coalesce both "hover" and
            # "popup_open" states in one so that the hover background stays
            # active even when the popup menu is open.
            old_hover = self.hover
            self.hover = self.hover or self.__popup_open

            self.draw_background(ctx, rect)
            self.draw_icon(ctx)
            self.draw_label(ctx)

            # Restore old state
            self.hover = old_hover

            # Draw the custom popup indicator
            if self.__enable_popup and (self.hover or self.__popup_open):
                self.__draw_popup_indicator(ctx)

        except Exception as exception:
            logging.error('Could not draw a ProgramButton widget: %s',
                          str(exception))

        # return True to prevent default event processing
        return True


    # Draw the popup menu indicator
    def __draw_popup_indicator(self, ctx):
        # Background
        ctx.save()

        if self.__popup_hover:
            ctx.set_source_rgba(0.0, 1.0, 1.0, 1.0)
        else:
            ctx.set_source_rgba(0.0, 1.0, 1.0, 0.25)

        utils_gui.rounded_rectangle(
            ctx,
            x=self.__indicator_x1,
            y=self.__indicator_y1,
            width=self.INDICATOR_WIDTH,
            height=self.INDICATOR_HEIGHT,
            radius=3.0)

        ctx.fill()
        ctx.restore()

        # Foreground
        ctx.save()

        if self.__popup_hover:
            ctx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        else:
            ctx.set_source_rgba(0.0, 0.0, 0.0, 0.5)

        dots_x = self.__indicator_x1 + (self.INDICATOR_WIDTH / 2)
        dots_y = self.__indicator_y1 + (self.INDICATOR_HEIGHT / 4) + 1

        ctx.arc(dots_x, dots_y, self.INDICATOR_DOT_RADIUS, 0.0, math.pi * 2.0)
        dots_y += self.INDICATOR_DOT_RADIUS + self.INDICATOR_DOT_SPACING
        ctx.arc(dots_x, dots_y, self.INDICATOR_DOT_RADIUS, 0.0, math.pi * 2.0)
        dots_y += self.INDICATOR_DOT_RADIUS + self.INDICATOR_DOT_SPACING
        ctx.arc(dots_x, dots_y, self.INDICATOR_DOT_RADIUS, 0.0, math.pi * 2.0)

        ctx.fill()

        ctx.restore()


    # Create and display the popup menu
    def open_menu(self, widget, event):
        if self.disabled:
            return

        if not event.button in (1, 2, 3):
            return

        # Clicked the popup menu indicator
        if self.__enable_popup and self.__popup_hover:
            self.__menu = Gtk.Menu()

            if self.__have_desktop_dir:
                # Can't do this without the desktop directory
                desktop_item = Gtk.MenuItem(
                    utils.localize(STRINGS['popup_add_to_desktop'], self.__language))
                desktop_item.connect('activate',
                                     lambda x: self.__special_operation(
                                         self.parent.add_program_to_desktop))
                desktop_item.show()
                self.__menu.append(desktop_item)

            panel_item = Gtk.MenuItem(
                utils.localize(STRINGS['popup_add_to_panel'], self.__language))
            panel_item.connect('activate',
                               lambda x: self.__special_operation(
                                   self.parent.add_program_to_panel))
            panel_item.show()
            self.__menu.append(panel_item)

            if self.is_fave:
                # special entry for fave buttons
                remove_fave = Gtk.MenuItem(
                    utils.localize(STRINGS['popup_remove_from_faves'], self.__language))
                remove_fave.connect('activate',
                                    lambda x: self.__special_operation(
                                        self.parent.remove_program_from_faves))
                remove_fave.show()
                self.__menu.append(remove_fave)

            # Need to do things when the menu closes...
            self.__menu.connect('deactivate', self.__cancel_menu)

            # ...and if autohiding is enabled (like it usually is) we
            # must NOT hide the window when the menu opens!
            self.parent.disable_out_of_focus_hide()

            self.__popup_open = True
            self.__menu.popup(
                parent_menu_shell=None,
                parent_menu_item=None,
                func=None,
                data=None,
                button=event.button,
                activate_time=event.time)
            return True

        # Clicked on something else
        return False


    # Nothing in the popup menu was clicked
    def __cancel_menu(self, menushell):
        # Re-enable window autohiding
        self.parent.enable_out_of_focus_hide()

        self.__popup_open = False

        # Force hover state re-check
        x, y = self.get_pointer()
        self.__hover_check(x, y)

        self.__menu = None
        self.queue_draw()       # force redraw


    # The ProgramButton does not know how to add the program on the
    # desktop or panel or anything else, but the PuavoMenu class does,
    # so call the relevant method there. This is also a way to get
    # around Python's "no multiline lambdas" restriction.
    def __special_operation(self, method):
        if self.disabled:
            return

        self.parent.enable_out_of_focus_hide()

        self.__popup_open = False
        self.__menu = None
        self.__popup_hover = False
        self.queue_draw()       # force redraw

        method(self.data)
