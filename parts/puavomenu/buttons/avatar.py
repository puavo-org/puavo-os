# Custom username and user avatar button class

import logging

import gi
from gi.repository import Pango

from constants import SIDEBAR_WIDTH
import utils_gui

import buttons.base


# The user avatar and name are clickable, so we'll have to inherit from
# HoverIconButtonBase; Gtk.Label cannot be easily made to receive click
# events.
class AvatarButton(buttons.base.HoverIconButtonBase):
    ICON_SIZE = 48


    def __init__(self,
                 parent,
                 settings,
                 user_name,
                 initial_image=None,
                 tooltip=None):

        super().__init__(parent,
                         settings,
                         label=user_name,
                         icon=None,
                         tooltip=tooltip,
                         data=None)

        self.add_style_class('button_avatar')

        # Load the initial avatar image
        if initial_image:
            self.load_avatar(initial_image)
        else:
            self.icon = None

        self.label_layout.set_alignment(Pango.Alignment.LEFT)
        self.label_layout.set_width((SIDEBAR_WIDTH - self.ICON_SIZE - 8) * Pango.SCALE)
        self.label_layout.set_ellipsize(Pango.EllipsizeMode.END)

        self.compute_elements()


    def get_preferred_button_size(self):
        return (SIDEBAR_WIDTH, self.ICON_SIZE)


    def compute_elements(self):
        self.corner_rounding = 0

        self.icon_size = self.ICON_SIZE
        self.icon_pos = [0, 0]

        # Center the text vertically
        # (I can't figure out how to make Pango automatically center
        # text vertically. And even this is hacky :-( )
        ink, _ = self.label_layout.get_extents()

        self.label_pos = [
            self.ICON_SIZE + 16,
            (self.ICON_SIZE / 2) - ((ink.height / Pango.SCALE) / 2) - 5
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
                             self.icon_size, self.icon_size)


    # Loads and resizes the avatar icon
    def load_avatar(self, path):
        try:
            logging.info('Loading avatar image "%s"...', path)

            self.icon = \
                utils_gui.load_image_at_size(path,
                                             self.ICON_SIZE,
                                             self.ICON_SIZE)

            # trigger a redraw
            self.queue_draw()
        except Exception as exception:
            logging.error('Could not load avatar image "%s": %s',
                          path, str(exception))
            self.icon = None
