# Various custom buttons

import logging
import math

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
gi.require_version('PangoCairo', '1.0')
from gi.repository import Gtk, Gdk, Pango, PangoCairo

from constants import PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT, \
                      PROGRAM_BUTTON_ICON_SIZE, SIDEBAR_WIDTH
import utils
import utils_gui
from strings import STRINGS


class HoverIconButtonBase(Gtk.Button):
    """A general-purpose clickable button that displays an icon and
    a label. Reacts to mouse enter and leave events, highlighting the
    whole button area. Can optionally also display a tooltip text.
    This is a base class that does not do much. You MUST derive child
    class/-es that compute element sizes and positions if you want to
    use this!"""

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

        # Must be a valid icon loaded through IconCache, not a string
        self.icon = icon

        if tooltip:
            self.set_property('tooltip-text', tooltip)

        self.data = data

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
        # FIXME: Eww, hardcoded colors! Get these from the current
        # system theme somehow!
        self.icon_size = -1
        self.icon_pos = [-1, -1]
        self.icon_color = [1.0, 0.0, 0.0]
        self.label_pos = [-1, -1]
        self.label_color_normal = [0.0, 0.0, 0.0]
        self.label_color_hover = [1.0, 1.0, 1.0]
        self.background_color = [74.0 / 255.0, 144.0 / 255.0, 217.0 / 255.0]

        if settings.dark_theme:
            self.label_color_normal = [0.9, 0.9, 0.9]
            self.background_color = [33.0 / 255.0, 93.0 / 255.0, 156.0 / 255.0]

        self.corner_rounding = 0
        self.compute_elements()

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

            # setup the clipping area
            utils_gui.rounded_rectangle(ctx, 0, 0,
                                        rect.width, rect.height,
                                        self.corner_rounding)
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
        if not self.disabled and self.hover:
            utils_gui.rounded_rectangle(ctx,
                                        0, 0,
                                        rect.width, rect.height,
                                        self.corner_rounding)
            ctx.set_source_rgba(self.background_color[0],
                                self.background_color[1],
                                self.background_color[2],
                                1.0)
            ctx.fill()

    # Draw the icon
    def draw_icon(self, ctx):
        if self.icon:
            self.icon.draw(ctx, self.icon_pos[0], self.icon_pos[1])
        else:
            utils_gui.draw_x(ctx,
                             self.icon_pos[0], self.icon_pos[1],
                             self.icon_size, self.icon_size,
                             self.icon_color)

    # Draw the label
    def draw_label(self, ctx):
        ctx.move_to(self.label_pos[0], self.label_pos[1])

        if self.hover:
            ctx.set_source_rgba(self.label_color_hover[0],
                                self.label_color_hover[1],
                                self.label_color_hover[2],
                                1.0)
        else:
            ctx.set_source_rgba(self.label_color_normal[0],
                                self.label_color_normal[1],
                                self.label_color_normal[2],
                                1.0)

        ctx.move_to(self.label_pos[0], self.label_pos[1])
        PangoCairo.show_layout(ctx, self.label_layout)

    # It's possible to disable buttons, but because it's so rare
    # occurrence, you cannot set the flag in the constructor.
    # Instead, you must call this method. At the moment, a button
    # that gets disabled cannot be re-enabled.
    def disable(self):
        self.disabled = True
        self.label_color_normal = [0.5, 0.5, 0.5]


class ProgramButton(HoverIconButtonBase):
    """A normal program or weblink button."""

    # The hover indicator box
    INDICATOR_WIDTH = 20
    INDICATOR_HEIGHT = 30
    INDICATOR_EDGE = 5
    INDICATOR_ARROW_SIZE = 5

    def __init__(self,
                 parent,
                 settings,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 is_fave=False):

        super().__init__(parent, settings, label, icon, tooltip, data)

        self.is_fave = is_fave

        # Need this for localize()
        self.__language = settings.language

        if settings.desktop_dir is None:
            self.__have_desktop_dir = False
        else:
            self.__have_desktop_dir = True

        # Setup the popup menu
        self.__enable_popup = True
        self.__popup_hover = False
        self.__popup_open = False
        self.__hover_signal = None

        self.__menu = None
        self.__menu_signal = self.connect('button-press-event',
                                          self.open_menu)

        # We want mouse motion events
        self.set_events(self.get_events()
                        | Gdk.EventMask.POINTER_MOTION_MASK)

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

            # setup the clipping area
            utils_gui.rounded_rectangle(ctx,
                                        0, 0,
                                        rect.width, rect.height,
                                        self.corner_rounding)
            ctx.clip()

            # I don't want to copy-paste draw_background() and draw-label()
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

        utils_gui.rounded_rectangle(ctx,
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

        dot_radius = 2
        dot_spacing = 5.0
        dots_x = self.__indicator_x1 + (self.INDICATOR_WIDTH / 2)
        dots_y = self.__indicator_y1 + (self.INDICATOR_HEIGHT / 4) + 1

        ctx.arc(dots_x, dots_y, dot_radius, 0.0, math.pi * 2.0)
        dots_y += dot_radius + dot_spacing
        ctx.arc(dots_x, dots_y, dot_radius, 0.0, math.pi * 2.0)
        dots_y += dot_radius + dot_spacing
        ctx.arc(dots_x, dots_y, dot_radius, 0.0, math.pi * 2.0)
        ctx.fill()

        ctx.restore()

    # Create and display the popup menu
    def open_menu(self, widget, event):
        if self.disabled:
            return

        if event.button in (1, 2, 3):
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
        self.parent.enable_out_of_focus_hide()

        self.__popup_open = False

        # Force hover state re-check
        x, y = self.get_pointer()
        self.__hover_check(x, y)

        self.__menu = None
        self.queue_draw()       # force hover state update

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
        self.queue_draw()       # force hover state update ASAP

        method(self.data)


class MenuButton(HoverIconButtonBase):
    """A submenu button."""

    def __init__(self,
                 parent,
                 settings,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 background=None):

        super().__init__(parent, settings, label, icon, tooltip, data)

        self.background = background
        self.icon_color = [0.0, 0.0, 1.0]
        self.label_color_normal = [0.0, 0.0, 0.0]
        self.label_color_hover = [0.0, 0.0, 0.0]

        if settings.dark_theme:
            self.label_color_normal = [1.0, 1.0, 1.0]
            self.label_color_hover = [1.0, 1.0, 1.0]

    def get_preferred_button_size(self):
        return (PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT)

    def compute_elements(self):
        self.corner_rounding = 5

        self.icon_size = PROGRAM_BUTTON_ICON_SIZE

        # Note the Y positions in icon_pos and label_pos, they must be
        # shifted down by 5 pixels to "center" them on the button

        self.icon_pos = [
            (PROGRAM_BUTTON_WIDTH / 2) - (PROGRAM_BUTTON_ICON_SIZE / 2),
            25
        ]

        # Center the text horizontally
        self.label_pos = [
            10,  # left padding
            30 + PROGRAM_BUTTON_ICON_SIZE
        ]

    def draw_background(self, ctx, rect):
        super().draw_background(ctx, rect)

        # menu buttons have a "folder" background image
        if self.background:
            ctx.set_source_surface(self.background, 0, 0)
            ctx.rectangle(0, 0, 150, 110)
            ctx.fill()


# The user avatar and name are clickable, so we'll have to inherit from
# HoverIconButtonBase; Gtk.Label cannot be easily made to receive click
# events.
class AvatarButton(HoverIconButtonBase):
    """Username and user avatar button."""

    ICON_SIZE = 48

    def __init__(self,
                 parent,
                 settings,
                 user_name,
                 initial_image=None,
                 tooltip=None):

        super().__init__(parent, settings, label=user_name, icon=None,
                         tooltip=tooltip, data=None)

        # Load the initial avatar image
        if initial_image:
            self.load_avatar(initial_image)
        else:
            self.icon = None

        self.label_layout.set_alignment(Pango.Alignment.LEFT)
        self.label_layout.set_width(
            (SIDEBAR_WIDTH - self.ICON_SIZE - 8) * Pango.SCALE)
        self.label_layout.set_ellipsize(Pango.EllipsizeMode.END)

        # Ewww, hardcoded font name and size...
        self.label_layout.set_font_description(
            Pango.FontDescription('Cantarell Bold 11'))
        self.compute_elements()

    def get_preferred_button_size(self):
        return (SIDEBAR_WIDTH, self.ICON_SIZE)

    def compute_elements(self):
        self.corner_rounding = 0

        self.icon_size = self.ICON_SIZE
        self.icon_pos = [0, 0]

        # Center the text vertically
        # (I can't figure out how to make Pango automatically center
        # text vertically. :-( )
        ink, _ = self.label_layout.get_extents()

        self.label_pos = [
            self.ICON_SIZE + 8,
            (self.ICON_SIZE / 2) - ((ink.height / Pango.SCALE) / 2) - 2
        ]

    # Must override the base method - the user avatar is not stored in
    # any icon cache and the base method is trying to draw it from a
    # cache!
    def draw_icon(self, ctx):
        if self.icon:
            ctx.set_source_surface(self.icon, 0, 0)
            ctx.rectangle(0, 0, self.ICON_SIZE, self.ICON_SIZE)
            ctx.fill()
        else:
            utils_gui.draw_x(ctx,
                             self.icon_pos[0], self.icon_pos[1],
                             self.icon_size, self.icon_size,
                             self.icon_color)

    # Loads and resizes the avatar icon
    def load_avatar(self, path):
        try:
            logging.info('Loading avatar image "%s"...', path)

            self.icon = utils_gui.load_image_at_size(path,
                                                     self.ICON_SIZE,
                                                     self.ICON_SIZE)

            # trigger a redraw
            self.queue_draw()
        except Exception as exception:
            logging.error('Could not load avatar image "%s": %s',
                          path, str(exception))
            self.icon = None

    def disable(self):
        self.disabled = True
        # keep the normal label color


class SidebarButton(HoverIconButtonBase):
    """Button used in the sidebar. Unofficially these are called
    "system buttons"."""

    PADDING = 4
    ICON_SIZE = 32

    def __init__(self,
                 parent,
                 settings,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None):

        super().__init__(parent, settings, label, icon, tooltip, data)

        self.label_layout.set_width(-1)     # -1 turns off wrapping
        self.label_layout.set_ellipsize(Pango.EllipsizeMode.END)

    def get_preferred_button_size(self):
        return (
            SIDEBAR_WIDTH,
            self.ICON_SIZE + self.PADDING * 2
        )

    def compute_elements(self):
        self.corner_rounding = 3
        self.icon_size = self.ICON_SIZE
        self.icon_pos = [self.PADDING, self.PADDING]

        # Center the text vertically
        _, height = self.label_layout.get_size()

        self.label_pos = [
            self.PADDING + self.ICON_SIZE + self.PADDING * 2,
            (self.ICON_SIZE + self.PADDING * 2) / 2 - (height / Pango.SCALE / 2)
        ]

    def draw_icon(self, ctx):
        if self.icon:
            self.icon.draw(ctx, self.icon_pos[0], self.icon_pos[1])
        else:
            utils_gui.draw_x(ctx,
                             self.icon_pos[0], self.icon_pos[1],
                             self.icon_size, self.icon_size,
                             self.icon_color)

        if self.disabled:
            # hack to make the icon look "grayed out"
            # not a very good hack as the rectangle is quite visible
            ctx.set_source_rgba(0.96, 0.96, 0.96, 0.75)
            ctx.rectangle(self.icon_pos[0], self.icon_pos[1],
                          self.icon_size, self.icon_size)
            ctx.fill()
