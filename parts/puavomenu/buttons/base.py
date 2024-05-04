# Base class for various custom buttons

import enum
import logging
import typing

import gi

gi.require_version("Gtk", "3.0")  # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk, Pango

import utils_gui


class Layout(str, enum.Enum):
    VERTICAL = "vertical"
    HORIZONTAL = "horizontal"

    def __str__(self) -> str:
        return self.value


# A general-purpose clickable button that displays an icon and a
# label. Reacts to mouse enter and leave events, highlighting the
# whole button area. Can optionally also display a tooltip text.
# This is a base class that does not do much. You MUST derive child
# class/-es that compute element sizes and positions if you want to
# use this!
class HoverIconButtonBase(Gtk.Button):
    def __init__(
        self,
        *,
        parent,
        settings,
        label: str,
        layout: Layout,
        width: int,
        height: int,
        icon_size: int,
        style_class: str,
        dims,
        padding: typing.Optional[int] = None,
        icon=None,
        tooltip=None,
        data=None,
        do_word_wrap: bool = True,
    ):
        super().__init__()

        if padding is None:
            padding = dims.main_padding

        # Private instance variables
        self.__do_word_wrap = do_word_wrap
        self.__icon_cache = None
        self.__icon_handle = None
        self.__icon_size = icon_size
        self.__icon_surface = None
        self.__label = label
        self.__label_layout = None
        self.__label_pos = None
        self.__layout = Layout(layout)
        self.__padding = padding

        # Public instance variables
        self.data = data
        self.disabled = False
        self.hover = False
        self.parent = parent

        self.set_size_request(width, height)

        self.__calculate_icon_and_label_pos()

        # The icon is either a file path to an image or a tuple
        # containing a handle to the icon cache and an icon index.
        if isinstance(icon, str):
            self.load_icon(icon)
        elif (
            isinstance(icon, tuple)
            and len(icon) == 2
            and icon[0] is not None
            and icon[1] is not None
        ):
            self.__icon_cache, self.__icon_handle = icon

            if self.__icon_size != self.__icon_cache.icon_size:
                raise ValueError(
                    "icon_size does not match icon_cache.icon_size",
                    icon_size,
                    self.__icon_cache.icon_size,
                )

        if tooltip:
            self.set_property("tooltip-text", tooltip)

        self.add_style_class("pm_button")
        self.add_style_class(style_class)

        # Connect signals last, after all variables have been
        # validated, initialized and set.
        self.connect("enter-notify-event", self.on_mouse_enter)
        self.connect("leave-notify-event", self.on_mouse_leave)
        self.connect("draw", self.on_draw)

    def __calculate_icon_and_label_pos(self):
        width, height = self.get_size_request()

        label_width = None
        label_height = None
        try:
            self.__label_layout = self.create_pango_layout(self.__label)
            if self.__do_word_wrap:
                self.__label_layout.set_wrap(Pango.WrapMode.WORD_CHAR)
                self.__label_layout.set_width(
                    (width - 2 * self.__padding) * Pango.SCALE
                )
            else:
                self.__label_layout.set_width(-1)
                self.__label_layout.set_ellipsize(Pango.EllipsizeMode.END)
        except BaseException:
            # TODO: Under what circumstances does this happen in
            # practice? If text layoutting failes, then it means that
            # icons are displayed without text at all. I guess that is
            # still better than nothing, but it also indicates that
            # something is horribly broken right? And if yes, is it
            # really enought to just log the error and keep going?
            logging.exception("Failed to create Pango layout for text %r", self.__label)
        else:
            label_width, label_height = [
                d / Pango.SCALE for d in self.__label_layout.get_size()
            ]

        if self.__layout == Layout.VERTICAL:
            if label_height is not None:
                self.__icon_pos = (
                    width / 2 - self.__icon_size / 2,
                    height / 2 - (self.__icon_size + self.__padding + label_height) / 2,
                )
            else:
                self.__icon_pos = (
                    width / 2 - self.__icon_size / 2,
                    height / 2 - self.__icon_size / 2,
                )

            if label_width is not None:
                self.__label_pos = (
                    width / 2 - label_width / 2,
                    self.__icon_pos[1] + self.__icon_size + self.__padding,
                )

        elif self.__layout == Layout.HORIZONTAL:
            self.__icon_pos = (self.__padding, height / 2 - self.__icon_size / 2)

            if label_height is not None:
                self.__label_pos = (
                    self.__icon_pos[0] + self.__icon_size + self.__padding,
                    height / 2 - label_height / 2,
                )
        else:
            raise RuntimeError("unsupported layout", self.__layout)

    def add_style_class(self, clazz):
        self.get_style_context().add_class(clazz)

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
        except Exception:
            logging.exception("Could not draw a HoverIconButton widget")

        # return True to prevent default event processing
        return True

    # Draw the button background
    def draw_background(self, ctx, rect):
        style = self.get_style_context()
        Gtk.render_background(style, ctx, 0.0, 0.0, rect.width, rect.height)
        Gtk.render_frame(style, ctx, 0.0, 0.0, rect.width, rect.height)

    # Draw the icon
    def draw_icon(self, ctx):
        if self.__icon_surface is not None:
            ctx.set_source_surface(self.__icon_surface, 0, 0)
            ctx.rectangle(0, 0, self.__icon_size, self.__icon_size)
            ctx.fill()
        elif self.__icon_cache is not None:
            self.__icon_cache.draw_icon(
                self.__icon_handle, ctx, self.__icon_pos[0], self.__icon_pos[1]
            )
        else:
            utils_gui.draw_x(
                ctx,
                self.__icon_pos[0],
                self.__icon_pos[1],
                self.__icon_size,
                self.__icon_size,
            )

    # Draw the label
    def draw_label(self, ctx):
        if not self.__label_layout:
            return

        Gtk.render_layout(
            self.get_style_context(),
            ctx,
            self.__label_pos[0],
            self.__label_pos[1],
            self.__label_layout,
        )

    # It's possible to disable buttons, but because it's so rare
    # occurrence, you cannot set the flag in the constructor.
    # Instead, you must call this method. At the moment, a button
    # that gets disabled cannot be re-enabled.
    def disable(self):
        self.set_sensitive(False)
        self.disabled = True

    def load_icon(self, path):
        icon_surface = utils_gui.load_image_at_size(
            path, self.__icon_size, self.__icon_size
        )
        icon_size = f"{icon_surface.get_width()}x{icon_surface.get_height()}"
        expected_icon_size = f"{self.__icon_size}x{self.__icon_size}"
        if expected_icon_size != icon_size:
            raise ValueError(
                f"Invalid icon size, expected {expected_icon_size}, got {icon_size}"
            )

        self.__icon_surface = icon_surface
        self.queue_draw()

    def set_label_markup(self, markup):
        if self.__label_layout is not None:
            self.__label_layout.set_markup(markup)
        else:
            logging.error(
                "Failed to set label markup because Pango layout is not initialized"
            )
