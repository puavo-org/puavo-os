# Custom sidebar button class

import buttons.base
import constants


class SidebarButton(buttons.base.HoverIconButtonBase):
    def __init__(self, *, parent, settings, label, icon=None, tooltip=None, data=None):
        super().__init__(
            parent=parent,
            settings=settings,
            label=label,
            icon=icon,
            tooltip=tooltip,
            data=data,
            layout="horizontal",
            width=constants.SIDEBAR_WIDTH,
            height=constants.SIDEBAR_BUTTON_ICON_SIZE
            + constants.SIDEBAR_BUTTON_PADDING * 2,
            icon_size=constants.SIDEBAR_BUTTON_ICON_SIZE,
            padding=constants.SIDEBAR_BUTTON_PADDING,
            do_word_wrap=False,
            style_class="button_sidebar",
        )
