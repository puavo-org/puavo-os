# Custom username and user avatar button class

import constants
import buttons.base


# The user avatar and name are clickable, so we'll have to inherit from
# HoverIconButtonBase; Gtk.Label cannot be easily made to receive click
# events.
class AvatarButton(buttons.base.HoverIconButtonBase):
    def __init__(self, *, parent, settings, label, icon=None, tooltip=None):
        super().__init__(
            parent=parent,
            settings=settings,
            label=label,
            icon=icon,
            tooltip=tooltip,
            layout="horizontal",
            width=constants.SIDEBAR_WIDTH,
            height=constants.USER_AVATAR_SIZE,
            icon_size=constants.USER_AVATAR_SIZE,
            data=None,
            do_word_wrap=False,
            style_class="button_avatar",
        )
