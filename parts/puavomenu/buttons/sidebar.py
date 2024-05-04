# Custom sidebar button class

import buttons.base


class SidebarButton(buttons.base.HoverIconButtonBase):
    def __init__(
        self, *, parent, settings, label, dims, icon=None, tooltip=None, data=None
    ):
        super().__init__(
            parent=parent,
            settings=settings,
            label=label,
            icon=icon,
            tooltip=tooltip,
            data=data,
            dims=dims,
            layout="horizontal",
            width=dims.sidebar_width,
            height=dims.sidebar_button_icon_size + dims.sidebar_button_padding * 2,
            icon_size=dims.sidebar_button_icon_size,
            padding=dims.sidebar_button_padding,
            do_word_wrap=False,
            style_class="button_sidebar",
        )
