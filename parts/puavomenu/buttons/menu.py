# Custom menu button class

import buttons.base


class MenuButton(buttons.base.HoverIconButtonBase):
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
            layout="vertical",
            width=dims.program_button_width,
            height=dims.program_button_height,
            icon_size=dims.program_button_icon_size,
            style_class="button_menu",
        )
