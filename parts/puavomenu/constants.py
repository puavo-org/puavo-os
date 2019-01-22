# PuavoMenu constants

# Program types. Desktop is the default.
PROGRAM_TYPE_DESKTOP = 0
PROGRAM_TYPE_CUSTOM = 1
PROGRAM_TYPE_WEB = 2

# Size of the main menu window. Can be changed, but you have to change
# other element sizes too to accommodate the new size.
WINDOW_WIDTH = 955
WINDOW_HEIGHT = 592

# Main padding, used everywhere
# !!! DO NOT CHANGE! DOES NOT WORK PROPERLY YET! !!!
MAIN_PADDING = 10

# Size, in pixels, of the separator lines. Depends on the theme, so
# this unfortunately isn't very reliable.
SEPARATOR_SIZE = 1

# Width of the category selector
CATEGORIES_WIDTH = 400

# The back button
BACK_BUTTON_X = MAIN_PADDING
BACK_BUTTON_Y = 45
BACK_BUTTON_WIDTH = 50

SEARCH_WIDTH = 150
SEARCH_HEIGHT = 30

# Main programs list (also used to position/size the faves list)
PROGRAMS_TOP = 75
PROGRAMS_LEFT = MAIN_PADDING
PROGRAMS_HEIGHT = 375
PROGRAMS_WIDTH = 618
FAVES_TOP = PROGRAMS_TOP + PROGRAMS_HEIGHT + (MAIN_PADDING * 2)

# Icons per row in the programs/faves lists. DO NOT CHANGE unless you
# also make the window wider! The lists don't have horizontal scrollbars.
PROGRAMS_PER_ROW = 4

# Size of a program button
PROGRAM_BUTTON_WIDTH = 150
PROGRAM_BUTTON_HEIGHT = 110
PROGRAM_BUTTON_ICON_SIZE = 48

# How many faves to display
NUMBER_OF_FAVES = 4

# Sidebar main
SIDEBAR_TOP = 0
SIDEBAR_LEFT = PROGRAMS_LEFT + PROGRAMS_WIDTH + (MAIN_PADDING * 2)
SIDEBAR_WIDTH = WINDOW_WIDTH - SIDEBAR_LEFT - MAIN_PADDING

USER_AVATAR_TOP = MAIN_PADDING
USER_AVATAR_SIZE = 48

# Height of the machine name and release info text
HOSTINFO_LABEL_HEIGHT = 45

# Accepted extensions for icon files, in the order we prefer them. Some
# .desktop file "Icon" entries specify full paths, some only "generic"
# names, so to tell them apart, we check if the name has an extension.
ICON_EXTENSIONS = ['.svg', '.svgz', '.png', '.xpm', '.jpg', '.jpeg']
