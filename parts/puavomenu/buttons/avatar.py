# Custom username and user avatar button class

import buttons.base


# The user avatar and name are clickable, so we'll have to inherit from
# HoverIconButtonBase; Gtk.Label cannot be easily made to receive click
# events.
class AvatarButton(buttons.base.HoverIconButtonBase):
    def __init__(self, *, parent, settings, label, dims, icon=None, tooltip=None):
        super().__init__(
            parent=parent,
            settings=settings,
            label=label,
            icon=icon,
            tooltip=tooltip,
            dims=dims,
            layout="horizontal",
            width=dims.sidebar_width,
            height=dims.user_avatar_size,
            icon_size=dims.user_avatar_size,
            data=None,
            do_word_wrap=False,
            style_class="button_avatar",
        )
