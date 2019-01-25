# Converts YAML files and strings into menu data. Tries to validate the data
# so thoroughly that once it has been loaded, you can just use it without any
# further checks. (Yeah, right.)

import os.path
import logging

from constants import *
from menudata import Program, Menu, Category
import utils
import conditionals
from settings import SETTINGS


# Characters that can be used in program, menu and category IDs
ALLOWED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' \
                'abcdefghijklmnopqrstuvwxyz' \
                '0123456789' \
                '._-'


def __parse_list(lst):
    """Lists in YAML comes in many formats. Convert two of them into one
    unifid format."""

    if isinstance(lst, str):
        lst = lst.split(', ')

    if utils.is_empty(lst):
        return []

    return lst


def __convert_yaml_node(node):
    """YAML is the Perl of markup languages, there are so many ways to
    say the same thing. Support four different ways to specify a program
    and convert them all into one unified format."""

    status = True
    name = ''
    params = {}

    if isinstance(node, str):
        # - name  (note the lack of colon)
        name = node
    elif isinstance(node, dict):
        # - name:
        #     key1: value1
        #     key2: value2
        #     ....
        if len(node.keys()) != 1:
            raise RuntimeError('More than one key in a node')

        name = list(node.keys())[0]
        params = node[name]

        if isinstance(params, list):
            # a list of dicts, merge them
            params = {key: value for param in params for key, value in param.items()}
        elif params is None:
            # - name:  (note the colon)
            params = {}
    else:
        raise RuntimeError("Don't know what this is")

    return status, name, params


def __is_valid(string):
    for char in string:
        if char not in ALLOWED_CHARS:
            return False

    return True


def __parse_yml_string(string, conditions):
    """Loads menu data from YAML data stored in a string."""

    import yaml

    programs = {}
    menus = {}
    categories = {}

    # use safe_load(), it does not attempt to construct Python classes
    data = yaml.safe_load(string)

    if data is None or not isinstance(data, dict):
        logging.warning('__parse_yml_string(): string produced no data, or the '
                        'data is not a dict')
        return programs, menus, categories

    # data.get('xxx', []) will fail if the list following the key is
    # empty, returning None and crashing the program.
    if data.get('programs') is None:
        data['programs'] = []

    if data.get('menus') is None:
        data['menus'] = []

    if data.get('categories') is None:
        data['categories'] = []

    # --------------------------------------------------------------------------
    # Parse programs

    for i in data['programs']:
        status, name, params = __convert_yaml_node(i)

        if not status:
            continue

        if not __is_valid(name):
            logging.error('Program name "%s" contains invalid characters, '
                          'ignoring', name)
            continue

        if name in programs:
            logging.warning('Program "%s" defined multiple times, ignoring '
                            'duplicates', name)
            continue

        # "Reserve" the name so it's used even if we can't parse this
        # program definition, otherwise duplicate entries might slip
        # through
        programs[name] = None

        # Figure out the type
        prog_type = str(params.get('type', 'desktop'))

        if prog_type not in ('desktop', 'custom', 'web'):
            logging.error('Unknown program type "%s" for "%s", '
                          'ignoring definition', prog_type, name)
            continue

        program = Program()

        if prog_type == 'desktop':
            program.type = PROGRAM_TYPE_DESKTOP
        elif prog_type == 'custom':
            program.type = PROGRAM_TYPE_CUSTOM
        else:
            program.type = PROGRAM_TYPE_WEB

        program.name = name

        # Conditionally hidden?
        if 'condition' in params and \
                conditionals.is_hidden(conditions, params['condition'], name, 'program'):
            program.hidden = True

        # Load common parameters
        if 'name' in params:
            program.title = utils.localize(params['name'])

            if utils.is_empty(program.title):
                logging.error('Empty name given for "%s"', name)
                program.title = None

        if 'description' in params:
            program.description = utils.localize(params['description'])

            if utils.is_empty(program.description):
                logging.warning('Ignoring empty description for program "%s"',
                                name)
                program.description = None

        if 'icon' in params:
            program.icon_name = str(params['icon'])

            if utils.is_empty(program.icon_name):
                logging.warning('Ignoring empty icon for "%s"', name)
                program.icon_name = None

        program.keywords = __parse_list(params.get('keywords', []))

        # Per-program tags, if any
        for tag in __parse_list(params.get('tags', '')):
            if len(tag) > 0:
                program.tags.add(tag.lower())

        # Some per-type additional checks
        if program.type in (PROGRAM_TYPE_CUSTOM, PROGRAM_TYPE_WEB):
            if program.title is None:
                logging.error('Custom program/web link "%s" has no name at '
                              'all, ignoring definition', name)
                continue

            if program.icon_name is None:
                # this isn't fatal, it just looks really ugly
                logging.warning('Custom program/web link "%s" is missing an '
                                'icon definition', name)

        # Load type-specific parameters
        if program.type == PROGRAM_TYPE_DESKTOP:
            if 'command' in params:
                # allow overriding of the "Exec" definition
                program.command = str(params['command'])

                if utils.is_empty(program.command):
                    logging.warning('Ignoring empty command override for desktop '
                                    'program "%s"', name)
                    program.command = None

        elif program.type == PROGRAM_TYPE_CUSTOM:
            if 'command' not in params or utils.is_empty(params['command']):
                logging.error("Custom program \"%s\" has no command defined"
                              "(or it's empty), ignoring command definition",
                              name)
                continue

            program.command = str(params['command'])

        elif program.type == PROGRAM_TYPE_WEB:
            if ('url' not in params) or utils.is_empty(params['url']):
                logging.error("Web link \"%s\" has no URL defined (or it's "
                              "empty), ignoring link definition",
                              name)
                continue

            program.command = str(params['url'])

        # Actually use the reserved slot
        programs[name] = program

    # --------------------------------------------------------------------------
    # Parse menus

    for i in data['menus']:
        status, name, params = __convert_yaml_node(i)

        if not status:
            continue

        if not __is_valid(name):
            logging.error('Menu name "%s" contains invalid characters, '
                          'ignoring', name)
            continue

        if name in menus:
            logging.error('Menu "%s" defined multiple times, ignoring '
                          'duplicates', name)
            continue

        # Like programs, reserve the name to prevent duplicates
        menus[name] = None

        menu = Menu()
        menu.name = name

        # Conditionally hidden?
        if 'condition' in params and \
                conditionals.is_hidden(conditions, params['condition'], name, 'menu'):
            menu.hidden = True

        menu.title = utils.localize(params.get('name', ''))

        if utils.is_empty(menu.title):
            logging.error('Menu "%s" has no name at all, menu ignored', name)
            continue

        if 'description' in params:
            menu.description = utils.localize(params['description'])

            if utils.is_empty(menu.description):
                logging.warning('Ignoring empty description for menu "%s"', name)
                menu.description = None

        if 'icon' in params:
            menu.icon_name = str(params['icon'])

        if utils.is_empty(menu.icon_name):
            logging.warning('Menu "%s" has a missing/empty icon', name)
            menu.icon_name = None

        menu.programs = __parse_list(params.get('programs', []))

        if utils.is_empty(menu.programs):
            logging.warning('Menu "%s" has no programs defined for it at all',
                            name)
            menu.programs = []

        # Actually use the reserved slot
        menus[name] = menu

    # --------------------------------------------------------------------------
    # Parse categories

    for i in data['categories']:
        status, name, params = __convert_yaml_node(i)

        if not status:
            continue

        if not __is_valid(name):
            logging.error('Category name "%s" contains invalid characters, '
                          'ignoring', name)
            continue

        if name in categories:
            logging.error('Category "%s" defined multiple times, ignoring '
                          'duplicates', name)
            continue

        # Again reserve the name to prevent duplicates
        categories[name] = None

        cat = Category()
        cat.name = name

        # Conditionally hidden?
        if 'condition' in params and \
                conditionals.is_hidden(conditions, params['condition'], name, 'category'):
            cat.hidden = True

        cat.title = utils.localize(params.get('name', ''))

        if utils.is_empty(cat.title):
            logging.error('Category "%s" has no name at all, '
                          'category ignored', name)
            continue

        if 'position' in params:
            try:
                cat.position = int(params['position'])
            except ValueError:
                logging.warning('Cannot interpret "%s" as a position for '
                                'category "%s", defaulting to 0',
                                params["position"], name)
                cat.position = 0

        cat.menus = __parse_list(params.get('menus', []))
        cat.programs = __parse_list(params.get('programs', []))

        if utils.is_empty(cat.menus) and utils.is_empty(cat.programs):
            logging.warning('Category "%s" has no menus or programs defined '
                            'for it at all', name)

        # Actually use the reserved slot
        categories[name] = cat

    return programs, menus, categories


def __parse_yml_file(name, conditions):
    """Loads menu data from a YAML file."""
    return __parse_yml_string(
        open(name, mode='r', encoding='utf-8'),
        conditions)


def __load_dotdesktop_file(name):
    """Fairly robust .desktop file parser. Tries to extract as much
    valid data as possible, returns dicts within dicts.

    Reference: https://standards.freedesktop.org/desktop-entry-spec/latest/
    Referenced: 2017-07-25."""

    section = None
    data = {}

    for l in open(name, mode='r', encoding='utf-8').readlines():
        l = l.strip()

        if utils.is_empty(l) or l[0] == '#':
            continue

        if l[0] == '[' and l[-1] == ']':    # [section name]
            sect_name = l[1:-1].strip()

            if utils.is_empty(sect_name):
                # Nothing in the spec says that empty section names are
                # invalid, but what on Earth would we do with them?
                logging.warning('Desktop file "%s" contains an empty '
                                'section name', name)
                section = None

            if sect_name in data:
                # Section names must be unique
                logging.warning('Desktop file "%s" contains a '
                                'duplicate section', name)
                section = None

            data[sect_name] = {}
            section = data[sect_name]
        else:                                   # key=value
            equals = l.find('=')

            if equals != -1 and section is not None:
                key = l[0:equals].strip()
                value = l[equals+1:].strip()

                # The spec says nothing about empty keys and values, but I
                # guess it's reasonable to allow empty values but not empty
                # keys
                if utils.is_empty(key):
                    continue

                if key in section:
                    # The spec does, however, say that keys within a section
                    # must be unique
                    logging.warning('Desktop file "%s" contains duplicate '
                                    'keys ("%s") within the same section',
                                    name, key)
                    continue

                section[key] = value

    return data


# ------------------------------------------------------------------------------


def load_menu_data(source, desktop_dirs, conditions):
    """The main menu loader function. Call this."""

    import time

    programs = {}
    menus = {}
    categories = {}
    category_index = []

    # --------------------------------------------------------------------------
    # Step 1: Parse all available menudata files

    total_start = time.clock()
    start_time = total_start

    logging.info('Have %d source(s) for menu data', len(source))

    for name in source:
        try:
            logging.info('Loading menudata file "%s"...', name)
            p, m, c = __parse_yml_file(name, conditions)
        except Exception as exception:
            logging.error('Could not load file "%s": %s', name, str(exception))
            continue

        # IDs must be unique within a file, but not across files; a file
        # loaded later can overwrite/replace earlier definitions. This is
        # by design.
        programs.update(p)
        menus.update(m)
        categories.update(c)

    end_time = time.clock()
    utils.log_elapsed_time('YAML loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Step 2: Load the .desktop files for desktop programs

    start_time = time.clock()

    if utils.is_empty(desktop_dirs):
        logging.warning('No .desktop file search paths specified!')

    for name, program in programs.items():
        if not program:
            continue

        if program.type != PROGRAM_TYPE_DESKTOP:
            continue

        # Locate the .desktop file
        dd_name = None

        for d in desktop_dirs:
            full = os.path.join(d, program.name + '.desktop')

            if os.path.isfile(full):
                dd_name = full
                break

        if dd_name is None:
            logging.error('.desktop file for "%s" not found', program.name)

            # These programs are broken, so clear them
            programs[name] = None
            continue

        program.original_desktop_file = program.name + '.desktop'

        # Try to load it
        try:
            desktop_data = __load_dotdesktop_file(dd_name)
        except Exception as exception:
            logging.error('Could not load file "%s":', dd_name)
            logging.error(exception, exc_info=True)
            programs[name] = None
            continue

        if 'Desktop Entry' not in desktop_data:
            logging.error("Can't load \"%s\" for \"%s\": No [Desktop Entry] "
                          "section in the file", dd_name, i)
            programs[name] = None
            continue

        entry = desktop_data['Desktop Entry']

        # Try to load the parts that we don't have yet from it
        if program.title is None:
            key = 'Name[' + SETTINGS.language + ']'

            if key in entry:
                # The best case: we have a localized name
                program.title = entry[key]
            else:
                # "Name" and "GenericName" aren't interchangeable, but this
                # is the best we can do. For example, if "Name" is "Mozilla",
                # then "GenericName" could be "Web Browser".
                key = 'GenericName[' + SETTINGS.language + ']'

                if key in entry:
                    program.title = entry[key]
                else:
                    # Last resort
                    #logging.warning('Have to use "Name" entry for program "%s"'.
                    #                program.name)
                    program.title = entry.get('Name', '')

            if utils.is_empty(program.title):
                logging.error('Empty name for program "%s", program ignored',
                              program.name)
                programs[name] = None
                continue

        if program.description is None:
            key = 'Comment[' + SETTINGS.language + ']'

            # Accept *ONLY* localized comments
            if key in entry:
                program.description = entry[key]

                if utils.is_empty(program.description):
                    logging.warning('Empty comment specified for program "%s" in '
                                    'the .desktop file "%s"', program.name, dd_name)
                    program.comment = None

        if utils.is_empty(program.keywords):
            key = 'Keywords[' + SETTINGS.language + ']'

            # Accept *ONLY* localized keyword strings
            if key in entry:
                program.keywords = list(filter(None, entry[key].split(";")))

        if program.icon_name is None:
            if 'Icon' not in entry:
                logging.warning('Program "%s" has no icon defined for it in the '
                                '.desktop file "%s"', program.name, dd_name)
            else:
                program.icon_name = entry.get('Icon', '')

        if utils.is_empty(program.icon_name):
            logging.warning('Program "%s" has an empty/invalid icon name, will '
                            'display incorrectly', program.name)
            program.icon_name = None

        if program.command is None:
            if 'Exec' not in entry or utils.is_empty(entry['Exec']):
                logging.warning('Program "%s" has an empty or missing "Exec" '
                                'line in the desktop file "%s", program ignored',
                                program.name, dd_name)
                programs[name] = None
                continue

            # Remove %XX parameters from the Exec key in the same way
            # Webmenu does it. It has worked fine for Webmenu, maybe
            # it works fine for us too...?
            # (Reference: file parts/webmenu/src/parseExec.coffee, line 24)
            # TODO: This is NOT okay.
            program.command = re.sub(r"%[fFuUdDnNickvm]{1}", "", entry['Exec'])

        # If the desktop file has categories, store them as tags
        if 'Categories' in entry:
            # Annoyingly, .desktop files use semicolons here,
            # but we use just spaces/commas
            for raw_tag in filter(None, entry['Categories'].split(';')):
                tag = raw_tag.strip()

                if len(tag) > 0:
                    program.tags.add(tag.lower())

        # Is the icon name a full path to an icon file, or just
        # a generic name?
        if program.icon_name:
            _, ext = os.path.splitext(program.icon_name)

            if (not utils.is_empty(ext)) and (ext in ICON_EXTENSIONS):
                program.icon_name_is_path = True

    end_time = time.clock()
    utils.log_elapsed_time('Desktop file parsing', start_time, end_time)

    # --------------------------------------------------------------------------
    # Step 3: Convert textual references into actual object references and
    # build the final menu data. Also mark used programs and menus while
    # we're at it.

    start_time = time.clock()

    for m in menus:
        menu = menus[m]

        if not menu:
            continue

        if menu.hidden:
            continue

        new_programs = []

        for p in menu.programs:
            if p in programs:
                if not programs[p]:
                    continue

                if not programs[p].hidden:
                    new_programs.append(programs[p])
                    programs[p].used = True
            else:
                logging.error('Menu "%s" references to a non-existent '
                              'program "%s"', m, p)

        menu.programs = new_programs

    for c in categories:
        cat = categories[c]

        if not cat:
            continue

        if cat.hidden:
            continue

        new_menus = []
        new_programs = []

        for m in cat.menus:
            if m in menus:
                if not menus[m]:
                    continue

                if not menus[m].hidden:
                    new_menus.append(menus[m])
                    menus[m].used = True
            else:
                logging.error('Category "%s" references to a non-existent '
                              'menu "%s"', c, m)

        for p in cat.programs:
            if p in programs:
                if not programs[p]:
                    continue

                if not programs[p].hidden:
                    new_programs.append(programs[p])
                    programs[p].used = True
            else:
                logging.error('Category "%s" references to a non-existent '
                              'program "%s"', c, p)

        cat.menus = new_menus
        cat.programs = new_programs

    # We can finally remove broken entries
    programs = {k: v for k, v in programs.items() if programs[k] is not None}
    menus = {k: v for k, v in menus.items() if menus[k] is not None}
    categories = {k: v for k, v in categories.items() if categories[k] is not None}

    # Warn about unused (and unhidden) programs, they just take up resources
    num_used_programs = 0
    num_used_menus = 0
    num_used_categories = 0

    for i in programs:
        p = programs[i]

        if not p.hidden and not p.used:
            logging.warning('Program "%s" defined but not used', p.name)

        if p.used and not p.hidden:
            num_used_programs += 1

    for i in menus:
        m = menus[i]

        if not m.hidden and not m.used:
            logging.warning('Menu "%s" defined but not used', m.name)

        if m.used and not m.hidden:
            num_used_menus += 1

    for i in categories:
        c = categories[i]

        if not c.hidden:
            num_used_categories += 1

    # --------------------------------------------------------------------------
    # Step 4: Sort the categories

    # Sort the categories by position, but if the positions are identical,
    # sort by names. Warning: the sort is not locale-aware or case
    # insensitive!
    index = []

    for i in categories:
        c = categories[i]

        if not c.hidden:
            index.append((c.position, c.name, i))

    index.sort(key=lambda c: (c[0], c[1]))

    # only IDs are used from hereon
    for c in index:
        category_index.append(c[1])

    end_time = time.clock()
    utils.log_elapsed_time('Menu data building time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Done

    logging.info(
        'Have %d programs (%d actually used), '
        '%d menus (%d actually used) and '
        '%d categories (%d actually used)',
        len(programs), num_used_programs,
        len(menus), num_used_menus,
        len(categories), num_used_categories)

    end_time = time.clock()
    utils.log_elapsed_time('Total menu parsing time', total_start, end_time)

    return programs, menus, categories, category_index
