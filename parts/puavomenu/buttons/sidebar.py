# Custom sidebar button class

import gi
from gi.repository import Pango

from constants import SIDEBAR_WIDTH

import utils_gui

import buttons.base


class SidebarButton(buttons.base.HoverIconButtonBase):
    PADDING = 4
    ICON_SIZE = 32


    def __init__(self,
                 parent,
                 settings,
                 label,
                 icon=None,
                 tooltip=None,
                 data=None):

        super().__init__(parent,
                         settings,
                         label,
                         icon,
                         tooltip,
                         data)

        self.add_style_class('button_sidebar')

        self.label_layout.set_width(-1)     # -1 turns off word wrapping
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
        if self.icon_cache:
            self.icon_cache.draw_icon(self.icon_handle,
                                      ctx,
                                      self.icon_pos[0], self.icon_pos[1])
        else:
            utils_gui.draw_x(ctx,
                             self.icon_pos[0], self.icon_pos[1],
                             self.icon_size, self.icon_size,
                             [1.0, 0.0, 0.0, 1.0])
