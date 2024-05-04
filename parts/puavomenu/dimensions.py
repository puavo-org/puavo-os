import logging


class Dims:
    def __init__(
        self,
        *,
        main_padding,
        programs_per_row,
        program_button_icon_size,
        user_avatar_size,
        programs_height,
        sidebar_width,
        sidebar_button_icon_size,
    ):
        # Main padding, used everywhere. Changing this shouldn't break anything,
        # but it's still not recommended unless you know what you're doing.
        self.main_padding = main_padding

        # Width of a scrollbar. I don't know any way to query this from GNOME,
        # so I took a screenshot and measured it.
        self.scrollbar_width = 16

        # Height of the separator label for search results
        self.programs_search_group_height = 25

        # Icons per row in program lists
        self.programs_per_row = programs_per_row

        # Size of a program button
        self.program_button_icon_size = program_button_icon_size

        # Size of the user avatar, in pixels
        self.user_avatar_size = user_avatar_size

        self.program_button_width = (
            self.program_button_icon_size + 2 * self.main_padding + 82
        )
        self.program_button_height = (
            self.program_button_icon_size + 2 * self.main_padding + 42
        )
        self.program_row_padding = 5
        self.program_col_padding = 5

        # Depends on how tall the category selector is
        self.programs_top = 80

        # Size of the programs list
        self.programs_width = (
            (self.program_button_width + self.program_row_padding)
            * self.programs_per_row
            - self.program_row_padding
            + self.scrollbar_width
        )
        self.programs_height = programs_height

        # Frequently-used programs list
        self.frequent_top = (
            self.programs_top + self.programs_height + (self.main_padding * 2)
        )

        # Can be whatever you want
        self.sidebar_width = sidebar_width
        self.sidebar_button_padding = 4
        self.sidebar_button_icon_size = sidebar_button_icon_size

        # Main window size
        self.window_width = (
            self.programs_width + self.sidebar_width + (self.main_padding * 4)
        )
        self.window_height = (
            self.frequent_top + self.program_button_height + self.main_padding * 3
        )

        # Sidebar
        self.sidebar_top = self.main_padding
        self.sidebar_left = self.programs_width + (self.main_padding * 3)
        self.sidebar_height = self.window_height - (self.main_padding * 2)

        # ------------------------------------------------------------------------------
        # Element positioning and sizing. Some of these do affect the main window size.

        # Size, in pixels, of the separator lines. Depends on the theme, so
        # this unfortunately isn't very reliable.
        self.separator_size = 1

        # Width of the category selector
        self.categories_width = self.programs_width

        # The back button
        self.back_button_y = 40
        self.back_button_width = 50

        # Search box
        self.search_width = 150

        # Height of the machine name and release info text
        self.hostinfo_label_height = 36


def get_low_res_dims():
    logging.info("Returning dimensions suitable for low resolution displays")

    return Dims(
        main_padding=4,
        programs_per_row=4,
        program_button_icon_size=24,
        user_avatar_size=24,
        programs_height=250,
        sidebar_button_icon_size=24,
        sidebar_width=200,
    )


def get_high_res_dims():
    logging.info("Returning dimensions suitable for high resolution displays")

    return Dims(
        main_padding=10,
        programs_per_row=4,
        program_button_icon_size=48,
        user_avatar_size=48,
        programs_height=400,
        sidebar_button_icon_size=32,
        sidebar_width=280,
    )


def get_optimal_dims(resolution):
    width, height = resolution

    if width * height < 1280 * 800:
        return get_low_res_dims()

    return get_high_res_dims()
