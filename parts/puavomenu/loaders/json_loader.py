# Menudata JSON loading and validation

import logging
import json


# Permitted top-level properties for programs, menus and categories.
# Other keys are simply stripped at load-time and the program never
# sees them.

VALID_PROGRAM_PROPERTIES = frozenset([
    # Note the lack of "type" here. It is handled separately.
    'name', 'description', 'icon', 'command', 'url', 'keywords', 'tags',
    'condition', 'puavopkg', 'hidden_by_default'
])

VALID_MENU_PROPERTIES = frozenset([
    'name', 'position', 'description', 'icon', 'condition', 'programs',
    'hidden_by_default'
])

VALID_CATEGORY_PROPERTIES = frozenset([
    'name', 'position', 'menus', 'programs', 'condition', 'hidden_by_default'
])


# Characters that can be used in program, menu and category IDs. For
# desktop programs, these IDs are also filenames, so anything that's
# allowed in filenames must also be allowed here. (Up to a point.)
ALLOWED_CHARS = frozenset('ABCDEFGHIJKLMNOPQRSTUVWXYZ' \
                          'abcdefghijklmnopqrstuvwxyz' \
                          '0123456789' \
                          '.-_')


def is_valid(string):
    for char in string:
        if char not in ALLOWED_CHARS:
            return False

    return True


def convert_to_set(src):
    if not src:
        return set()

    if isinstance(src, str):
        # support comma and whitespace -separated lists
        return set(src.split(', '))

    # assume it's iterable
    return set(src)


# Converts a "raw" program definition (loaded from JSON) to a
# minimally-validated dict. Returns None if the program
# definition was not valid.
def convert_program(prog_id, src_program):
    # Used to denote automatically loaded user programs
    if prog_id.startswith('user-program-'):
        logging.error(
            'Program ID "%s" is not valid; "user-program-" is an internally-used reserved prefix',
            prog_id)
        return None

    prog_type = src_program.get('type', 'desktop')

    if prog_type not in ('desktop', 'custom', 'web'):
        logging.error('Program "%s" has an unknown type "%s"', prog_id, prog_type)
        return None

    dst_program = {}

    for name in VALID_PROGRAM_PROPERTIES:
        if name in src_program:
            dst_program[name] = src_program[name]

    dst_program['type'] = prog_type

    if 'keywords' in dst_program:
        dst_program['keywords'] = convert_to_set(dst_program['keywords'])

    if 'tags' in dst_program:
        dst_program['tags'] = convert_to_set(dst_program['tags'])

    dst_program['flags'] = 0

    return dst_program


def convert_menu(src_menu):
    dst_menu = {}

    for name in VALID_MENU_PROPERTIES:
        if name in src_menu:
            dst_menu[name] = src_menu[name]

    dst_menu['flags'] = 0

    return dst_menu


def convert_category(src_category):
    dst_category = {}

    for name in VALID_CATEGORY_PROPERTIES:
        if name in src_category:
            dst_category[name] = src_category[name]

    dst_category['flags'] = 0

    return dst_category


# Call this to load a JSON menudata file
def load_raw_menudata(json_string, orig_filename):
    programs = {}
    menus = {}
    categories = {}

    data = json.loads(json_string or '{}')

    if data and isinstance(data, dict):
        raw_programs = data.get('programs', {})
        raw_menus = data.get('menus', {})
        raw_categories = data.get('categories', {})

        for program_id in raw_programs:
            if not is_valid(program_id):
                logging.error('Program ID "%s" contains invalid characters',
                              program_id)
                continue

            dst_program = convert_program(program_id, raw_programs[program_id])

            if dst_program:
                programs[program_id] = dst_program

        for menu_id in raw_menus:
            if not is_valid(menu_id):
                logging.error('Menu ID "%s" contains invalid characters',
                              menu_id)
                continue

            dst_menu = convert_menu(raw_menus[menu_id])

            if dst_menu:
                menus[menu_id] = dst_menu

        for category_id in raw_categories:
            if not is_valid(category_id):
                logging.error('Category ID "%s" contains invalid characters',
                              category_id)
                continue

            dst_category = convert_category(raw_categories[category_id])

            if dst_category:
                categories[category_id] = dst_category
    else:
        logging.warning('load_raw_menudata(): got no data from file "%s"', orig_filename)

    return programs, menus, categories
