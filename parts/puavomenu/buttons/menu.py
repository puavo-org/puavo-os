# Custom menu button class

import constants
import buttons.base


class MenuButton(buttons.base.HoverIconButtonBase):
    def __init__(self, *, parent, settings, label, icon=None, tooltip=None, data=None):
        super().__init__(
            parent=parent,
            settings=settings,
            label=label,
            icon=icon,
            tooltip=tooltip,
            data=data,
            layout="vertical",
            width=constants.PROGRAM_BUTTON_WIDTH,
            height=constants.PROGRAM_BUTTON_HEIGHT,
            icon_size=constants.PROGRAM_BUTTON_ICON_SIZE,
            style_class="button_menu",
        )
