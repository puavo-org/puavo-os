# Various custom buttons

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
gi.require_version('PangoCairo', '1.0')
from gi.repository import Gtk, Pango, PangoCairo

from logger import error as log_error, info as log_info
from constants import PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT, \
                      PROGRAM_BUTTON_ICON_SIZE, SIDEBAR_WIDTH
from iconcache import ICONS32, ICONS48
from utils import localize
from utils_gui import rounded_rectangle, draw_x, load_image_at_size
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
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 dark=False):

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

        # Dark colors?
        self.dark = dark

        # Not disabled by default
        self.disabled = False

        # For rendering the label
        self.label_layout = self.create_pango_layout(label)
        self.label_layout.set_alignment(Pango.Alignment.CENTER)
        self.label_layout.set_wrap(Pango.WrapMode.WORD_CHAR)
        self.label_layout.set_width((width - 20) * Pango.SCALE)

        # Hover state
        self.hover = False

        # Use this if you want to open popup menus
        self.menu_open = False

        # Set these in derived classes to control the look
        self.icon_size = -1
        self.icon_pos = [-1, -1]
        self.icon_color = [1.0, 0.0, 0.0]
        self.label_pos = [-1, -1]
        self.label_color_normal = [0.0, 0.0, 0.0]

        if self.dark:
            self.label_color_normal = [1.0, 1.0, 1.0]

        self.label_color_hover = [1.0, 1.0, 1.0]
        self.background_color = [74.0 / 255.0, 144.0 / 255.0, 217.0 / 255.0]
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

            # clipping area
            rounded_rectangle(ctx, 0, 0,
                              rect.width, rect.height,
                              self.corner_rounding)
            ctx.clip()

            self.draw_background(ctx, rect)
            self.draw_icon(ctx)
            self.draw_label(ctx)
        except Exception as e:
            log_error('Could not draw a HoverIconButton widget: {0}'.
                      format(str(e)))

        # return True to prevent default event processing
        return True


    # Draw the button background
    def draw_background(self, ctx, rect):
        if not self.disabled and (self.hover or self.menu_open):
            rounded_rectangle(ctx, 0, 0, rect.width, rect.height,
                              self.corner_rounding)
            ctx.set_source_rgba(self.background_color[0],
                                self.background_color[1],
                                self.background_color[2],
                                1.0)
            ctx.fill()


    # Draw the icon
    def draw_icon(self, ctx):
        if self.icon:
            ICONS48.draw_icon(ctx,
                              self.icon,
                              self.icon_pos[0], self.icon_pos[1])
        else:
            draw_x(ctx,
                   self.icon_pos[0], self.icon_pos[1],
                   self.icon_size, self.icon_size,
                   self.icon_color)


    # Draw the label
    def draw_label(self, ctx):
        ctx.move_to(self.label_pos[0], self.label_pos[1])

        if self.hover or self.menu_open:
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

    WIDTH = 150

    def __init__(self,
                 parent,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 is_fave=False,
                 dark=False):

        super().__init__(parent, label, icon=icon, tooltip=tooltip, data=data, dark=dark)

        self.is_fave = is_fave
        self.menu = None
        self.menu_signal = self.connect('button-press-event',
                                        self.open_menu)


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


    # Create and display the popup menu
    def open_menu(self, widget, event):
        if self.disabled:
            return

        if event.button == 3:
            self.menu = Gtk.Menu()

            desktop_item = Gtk.MenuItem(
                localize(STRINGS['popup_add_to_desktop'],
                         self.parent.language))
            desktop_item.connect('activate',
                                 lambda x: self.__special_operation(
                                     self.parent.add_program_to_desktop))
            desktop_item.show()
            self.menu.append(desktop_item)

            panel_item = Gtk.MenuItem(
                localize(STRINGS['popup_add_to_panel'],
                         self.parent.language))
            panel_item.connect('activate',
                               lambda x: self.__special_operation(
                                   self.parent.add_program_to_panel))
            panel_item.show()
            self.menu.append(panel_item)

            if self.is_fave:
                # special entry for fave buttons
                remove_fave = Gtk.MenuItem(
                    localize(STRINGS['popup_remove_from_faves'],
                             self.parent.language))
                remove_fave.connect('activate',
                                    lambda x: self.__special_operation(
                                        self.parent.remove_program_from_faves))
                remove_fave.show()
                self.menu.append(remove_fave)

            # Need to do things when the menu closes...
            self.menu.connect('deactivate', self.__cancel_menu)

            # ...and if autohiding is enabled (like it usually is) we
            # must NOT hide the window when the menu opens!
            self.parent.disable_out_of_focus_hide()

            self.menu_open = True
            self.menu.popup(
                parent_menu_shell=None,
                parent_menu_item=None,
                func=None,
                data=None,
                button=event.button,
                activate_time=event.time)


    # Nothing in the popup menu was clicked
    def __cancel_menu(self, menushell):
        self.parent.enable_out_of_focus_hide()

        self.menu_open = False
        self.menu = None
        self.queue_draw()       # force hover state update


    # The ProgramButton does not know how to add the program on the
    # desktop or panel or anything else, but the PuavoMenu class does,
    # so call the relevant method there. This is also a way to get
    # around Python's "no multiline lambdas" restriction.
    def __special_operation(self, method):
        if self.disabled:
            return

        self.parent.enable_out_of_focus_hide()

        self.menu_open = False
        self.menu = None
        self.queue_draw()       # force hover state update
        method(self.data)


class MenuButton(ProgramButton):
    """A submenu button."""

    def __init__(self,
                 parent,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 background=None,
                 dark=False):

        super().__init__(parent, label, icon=icon, tooltip=tooltip, data=data, dark=dark)

        self.background = background
        self.icon_color = [0.0, 0.0, 1.0]
        self.label_color_normal = [0.0, 0.0, 0.0]
        self.label_color_hover = [0.0, 0.0, 0.0]

        # menu buttons don't have popup menus
        self.disconnect(self.menu_signal)
        self.menu_signal = None


    def compute_elements(self):
        super().compute_elements()

        # push the elements downwards
        self.icon_pos[1] += 5
        self.label_pos[1] += 5


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
                 user_name,
                 initial_image=None,
                 tooltip=None,
                 dark=False):

        super().__init__(parent, label=user_name, icon=None,
                         tooltip=tooltip, data=None, dark=dark)

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
            draw_x(ctx,
                   self.icon_pos[0], self.icon_pos[1],
                   self.icon_size, self.icon_size,
                   self.icon_color)


    # Loads and resizes the avatar icon
    def load_avatar(self, path):
        try:
            log_info('Loading avatar image "{0}"...'.format(path))

            self.icon = load_image_at_size(path,
                                           self.ICON_SIZE,
                                           self.ICON_SIZE)

            # trigger a redraw
            self.queue_draw()
        except Exception as e:
            log_error('Could not load avatar image "{0}": {1}'.
                      format(path, str(e)))
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
                 label,
                 icon=None,
                 tooltip=None,
                 data=None,
                 dark=False):

        super().__init__(parent, label, icon=icon, tooltip=tooltip, data=data, dark=dark)

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
        # Use the 32-pixel icon cache for sidebar buttons, not 48
        if self.icon:
            ICONS32.draw_icon(ctx,
                              self.icon,
                              self.icon_pos[0], self.icon_pos[1])
        else:
            draw_x(ctx,
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
