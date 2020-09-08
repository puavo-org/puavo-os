# PuavoMenu constants

import enum

# ------------------------------------------------------------------------------
# Changing these will change the main window size!

# Main padding, used everywhere. Changing this shouldn't break anything,
# but it's still not recommended unless you know what you're doing.
MAIN_PADDING = 10

# Width of a scrollbar. I don't know any way to query this from GNOME,
# so I took a screenshot and measured it.
SCROLLBAR_WIDTH = 16

# Icons per row in program lists
PROGRAMS_PER_ROW = 4

PROGRAM_BUTTON_WIDTH = 150
PROGRAM_BUTTON_HEIGHT = 110
PROGRAM_ROW_PADDING = 5
PROGRAM_COL_PADDING = 5

# Depends on how tall the category selector is
PROGRAMS_TOP = 80

# Size of the programs list
PROGRAMS_WIDTH = (PROGRAM_BUTTON_WIDTH + PROGRAM_ROW_PADDING) * PROGRAMS_PER_ROW - \
    PROGRAM_ROW_PADDING + SCROLLBAR_WIDTH
PROGRAMS_HEIGHT = 400

# Frequently-used programs list
FREQUENT_TOP = PROGRAMS_TOP + PROGRAMS_HEIGHT + (MAIN_PADDING * 2)

# Can be whatever you want
SIDEBAR_WIDTH = 280

# Main window size
WINDOW_WIDTH = PROGRAMS_WIDTH + SIDEBAR_WIDTH + (MAIN_PADDING * 4)
WINDOW_HEIGHT = FREQUENT_TOP + PROGRAM_BUTTON_HEIGHT + MAIN_PADDING * 3

# Sidebar
SIDEBAR_TOP = MAIN_PADDING
SIDEBAR_LEFT = PROGRAMS_WIDTH + (MAIN_PADDING * 3)
SIDEBAR_HEIGHT = WINDOW_HEIGHT - (MAIN_PADDING * 2)

# ------------------------------------------------------------------------------
# Element positioning and sizing. Some of these do affect the main window size.

# Size, in pixels, of the separator lines. Depends on the theme, so
# this unfortunately isn't very reliable.
SEPARATOR_SIZE = 1

# Width of the category selector
CATEGORIES_WIDTH = PROGRAMS_WIDTH

# The back button
BACK_BUTTON_Y = 40
BACK_BUTTON_WIDTH = 50

# Search box
SEARCH_WIDTH = 150

# Size of a program button
PROGRAM_BUTTON_ICON_SIZE = 48

USER_AVATAR_SIZE = 48

# Height of the machine name and release info text
HOSTINFO_LABEL_HEIGHT = 36

# Accepted languages. These are permitted for the --lang parameter and
# environment variables, and we try to load strings from YAML/JSON/
# .desktop files for each of these.
LANGUAGES = frozenset(('en', 'fi', 'sv', 'de'))
