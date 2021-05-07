# Custom menu button class

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk, Gdk

from constants import PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT, \
                      PROGRAM_BUTTON_ICON_SIZE

import buttons.base


class MenuButton(buttons.base.HoverIconButtonBase):
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

        self.add_style_class('button_menu')


    def get_preferred_button_size(self):
        return (PROGRAM_BUTTON_WIDTH, PROGRAM_BUTTON_HEIGHT)


    def compute_elements(self):
        self.icon_size = PROGRAM_BUTTON_ICON_SIZE

        # Note the Y positions in icon_pos and label_pos, they must be
        # shifted down by 5 pixels to "center" them on the button
        self.icon_pos = [
            (PROGRAM_BUTTON_WIDTH / 2) - (PROGRAM_BUTTON_ICON_SIZE / 2),
            20
        ]

        # Center the text horizontally
        self.label_pos = [
            10,  # left padding
            25 + PROGRAM_BUTTON_ICON_SIZE
        ]
