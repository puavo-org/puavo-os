# Converts YAML files and strings into menu data. Tries to validate the data
# so thoroughly that once it has been loaded, you can just use it without any
# further checks. (Yeah, right.)

from os.path import join as path_join, \
                    isfile as is_file, \
                    splitext as split_ext

import traceback

import logger
from constants import PROGRAM_TYPE_DESKTOP, PROGRAM_TYPE_CUSTOM, \
                      PROGRAM_TYPE_WEB, ICON_EXTENSIONS
from menudata import Program, Menu, Category
from utils import localize, is_empty
from conditionals import is_hidden
from settings import SETTINGS


# Characters that can be used in program, menu and category IDs
ALLOWED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' \
                'abcdefghijklmnopqrstuvwxyz' \
                '0123456789' \
                '._-'


def __parse_list(l):
    """Lists in YAML comes in many formats. Convert two of them into one
    unifid format."""

    if isinstance(l, str):
        l = l.split(', ')

    if is_empty(l):
        return []

    return l


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
            params = {k: v for p in params for k, v in p.items()}
        elif params is None:
            # - name:  (note the colon)
            params = {}
    else:
        raise RuntimeError('Don\'t know what this is')

    return status, name, params


def __is_valid(s):
    for c in s:
        if c not in ALLOWED_CHARS:
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
        logger.warn('__parse_yml_string(): string produced no data, or the '
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
            logger.error('Program name "{0}" contains invalid characters, '
                         'ignoring'.format(name))
            continue

        if name in programs:
            logger.warn('Program "{0}" defined multiple times, ignoring '
                        'duplicates'.format(name))
            continue

        # "Reserve" the name so it's used even if we can't parse this
        # program definition, otherwise duplicate entries might slip
        # through
        programs[name] = None

        # Figure out the type
        prog_type = params.get('type', 'desktop')

        if prog_type not in ('desktop', 'custom', 'web'):
            logger.error('Unknown program type "{0}" for "{1}", '
                         'ignoring definition'.format(prog_type, name))
            continue

        p = Program()

        if prog_type == 'desktop':
            p.type = PROGRAM_TYPE_DESKTOP
        elif prog_type == 'custom':
            p.type = PROGRAM_TYPE_CUSTOM
        else:
            p.type = PROGRAM_TYPE_WEB

        p.name = name

        # Conditionally hidden?
        if 'condition' in params and \
                is_hidden(conditions, params['condition'], name):
            p.hidden = True
            programs[name] = p
            continue

        # Load common parameters
        if 'name' in params:
            p.title = localize(params['name'])

            if is_empty(p.title):
                logger.error('Empty name given for "{0}"'.format(name))
                p.title = None

        if 'description' in params:
            p.description = localize(params['description'])

            if is_empty(p.description):
                logger.warn('Ignoring empty description for program "{0}"'.
                            format(name))
                p.description = None

        if 'icon' in params:
            p.icon = str(params['icon'])

            if is_empty(p.icon):
                logger.warn('Ignoring empty icon for "{0}"'.format(name))
                p.icon = None

        p.keywords = __parse_list(params.get('keywords', []))

        # Some per-type additional checks
        if p.type in (PROGRAM_TYPE_CUSTOM, PROGRAM_TYPE_WEB):
            if p.title is None:
                logger.error('Custom program/web link "{0}" has no name at '
                             'all, ignoring definition'.format(name))
                continue

            if p.icon is None:
                # this isn't fatal, it just looks really ugly
                logger.warn('Custom program/web link "{0}" is missing an '
                            'icon definition'.format(name))

        # Load type-specific parameters
        if p.type == PROGRAM_TYPE_DESKTOP:
            if 'command' in params:
                # allow overriding of the "Exec" definition
                p.command = str(params['command'])

                if is_empty(p.command):
                    logger.warn('Ignoring empty command override for desktop '
                                'program "{0}"'.format(name))
                    p.command = None

        elif p.type == PROGRAM_TYPE_CUSTOM:
            if 'command' not in params or is_empty(params['command']):
                logger.error('Custom program "{0}" has no command defined'
                             '(or it\'s empty), ignoring command definition'.
                             format(name))
                continue

            p.command = str(params['command'])

        elif p.type == PROGRAM_TYPE_WEB:
            if ('url' not in params) or is_empty(params['url']):
                logger.error('Web link "{0}" has no URL defined (or it\'s '
                             'empty), ignoring link definition'.
                             format(name))
                continue

            p.command = str(params['url'])

        # Actually use the reserved slot
        programs[name] = p

    # --------------------------------------------------------------------------
    # Parse menus

    for i in data['menus']:
        status, name, params = __convert_yaml_node(i)

        if not status:
            continue

        if not __is_valid(name):
            logger.error('Menu name "{0}" contains invalid characters, '
                         'ignoring'.format(name))
            continue

        if name in menus:
            logger.error('Menu "{0}" defined multiple times, ignoring '
                         'duplicates'.format(name))
            continue

        # Like programs, reserve the name to prevent duplicates
        menus[name] = None

        m = Menu()
        m.name = name

        # Conditionally hidden?
        if 'condition' in params and \
                is_hidden(conditions, params['condition'], name):
            m.hidden = True
            menus[name] = m
            continue

        m.title = localize(params.get('name', ''))

        if is_empty(m.title):
            logger.error('Menu "{0}" has no name at all, menu ignored'.
                         format(name))
            continue

        if 'description' in params:
            m.description = localize(params['description'])

            if is_empty(m.description):
                logger.warn('Ignoring empty description for menu "{0}"'.
                            format(name))
                m.description = None

        if 'icon' in params:
            m.icon = str(params['icon'])

        if is_empty(m.icon):
            logger.warn('Menu "{0}" has a missing/empty icon'.
                        format(name))
            m.icon = None

        m.programs = __parse_list(params.get('programs', []))

        if is_empty(m.programs):
            logger.warn('Menu "{0}" has no programs defined for it at all'.
                        format(name))
            m.programs = []

        # Actually use the reserved slot
        menus[name] = m

    # --------------------------------------------------------------------------
    # Parse categories

    for i in data['categories']:
        status, name, params = __convert_yaml_node(i)

        if not status:
            continue

        if not __is_valid(name):
            logger.error('Category name "{0}" contains invalid characters, '
                         'ignoring'.format(name))
            continue

        if name in categories:
            logger.error('Category "{0}" defined multiple times, ignoring '
                         'duplicates'.format(name))
            continue

        # Again reserve the name to prevent duplicates
        categories[name] = None

        c = Category()
        c.name = name

        if 'condition' in params and \
                is_hidden(conditions, params['condition'], name):
            c.hidden = True
            categories[name] = c
            continue

        c.title = localize(params.get('name', ''))

        if is_empty(c.title):
            logger.error('Category "{0}" has no name at all, '
                         'category ignored'.format(name))
            continue

        if 'position' in params:
            try:
                c.position = int(params['position'])
            except ValueError:
                logger.warn('Cannot interpret "{0}" as a position for '
                            'category "{1}", defaulting to 0'.
                            format(params["position"], name))
                c.position = 0

        c.menus = __parse_list(params.get('menus', []))
        c.programs = __parse_list(params.get('programs', []))

        if is_empty(c.menus) and is_empty(c.programs):
            logger.warn('Category "{0}" has no menus or programs defined '
                        'for it at all'.format(name))

        # Actually use the reserved slot
        categories[name] = c

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

        if is_empty(l) or l[0] == '#':
            continue

        if l[0] == '[' and l[-1] == ']':    # [section name]
            sect_name = l[1:-1].strip()

            if is_empty(sect_name):
                # Nothing in the spec says that empty section names are
                # invalid, but what on Earth would we do with them?
                logger.warn('Desktop file "{0}" contains an empty '
                            'section name'.format(name))
                section = None

            if sect_name in data:
                # Section names must be unique
                logger.warn('Desktop file "{0}" contains a '
                            'duplicate section'.format(name))
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
                if is_empty(key):
                    continue

                if key in section:
                    # The spec does, however, say that keys within a section
                    # must be unique
                    logger.warn('Desktop file "{0}" contains duplicate '
                                'keys within the same section'.
                                format(name))
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
    # Step 1: Parse inputs

    total_start = time.clock()
    start_time = total_start

    logger.info('Have {0} sources for menu data'.format(len(source)))

    for n, s in enumerate(source):
        try:
            if s[0] == 'f':
                logger.info('load_menu_data(): loading a file "{0}" for '
                            'locale "{1}"...'.format(s[1], SETTINGS.language))

                p, m, c = __parse_yml_file(s[1], conditions)
            elif s[0] == 's':
                logger.info('load_menu_data(): loading a string for '
                            'locale "{0}"...'.format(SETTINGS.language))

                p, m, c = __parse_yml_string(s[1], conditions)
            else:
                logger.error('Source type "{0}" is not valid, skipping'.
                             format(s[0]))
                continue
        except Exception as e:
            if s[0] == 'f':
                logger.error('Could not load source file {0} ("{1}"): {2}'.
                             format(n + 1, s[1], str(e)))
            else:
                logger.error('Could not load source string {0}: {1}'.
                             format(n + 1, str(e)))

            logger.traceback(traceback.format_exc())
            continue

        # IDs must be unique within a file, but not across files; a file
        # loaded later can overwrite/replace earlier definitions. This is
        # by design.
        programs.update(p)
        menus.update(m)
        categories.update(c)

    # Remove missing and/or invalid entries. We've reserved their IDs,
    # but we couldn't load them.
    programs = {k: v for k, v in programs.items() if programs[k] is not None}
    menus = {k: v for k, v in menus.items() if menus[k] is not None}
    categories = {k: v for k, v in categories.items() if categories[k] is not None}

    end_time = time.clock()
    logger.print_time('YAML loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Step 2: Load the .desktop files for desktop programs

    start_time = time.clock()

    if is_empty(desktop_dirs):
        logger.warn('No .desktop file search paths specified!')

    for i in programs:
        p = programs[i]

        if p.hidden or p.type != PROGRAM_TYPE_DESKTOP:
            continue

        # Locate the .desktop file
        dd_name = None

        for d in desktop_dirs:
            full = path_join(d, p.name + '.desktop')

            if is_file(full):
                dd_name = full
                break

        if dd_name is None:
            logger.error('.desktop file for "{0}" not found'.
                         format(p.name))
            p.missing_desktop = True
            continue

        p.original_desktop_file = p.name + '.desktop'

        # Try to load it
        try:
            desktop_data = __load_dotdesktop_file(dd_name)
        except Exception as e:
            logger.error('Could not load file "{0}": {1}'.
                         format(dd_name, str(e)))
            logger.traceback(traceback.format_exc())
            p.missing_desktop = True
            continue

        if 'Desktop Entry' not in desktop_data:
            logger.error('Can\'t load "{0}" for "{1}": No [Desktop Entry] '
                         'section in the file'.format(dd_name, i))
            p.missing_desktop = True
            continue

        entry = desktop_data['Desktop Entry']

        # Try to load the parts that we don't have yet from it
        if p.title is None:
            key = 'Name[' + SETTINGS.language + ']'

            if key in entry:
                # The best case: we have a localized name
                p.title = entry[key]
            else:
                # "Name" and "GenericName" aren't interchangeable, but this
                # is the best we can do. For example, if "Name" is "Mozilla",
                # then "GenericName" could be "Web Browser".
                key = 'GenericName[' + SETTINGS.language + ']'

                if key in entry:
                    p.title = entry[key]
                else:
                    # Last resort
                    #logger.warn('Have to use "Name" entry for program "{0}"'.
                    #            format(p.name))
                    p.title = entry.get('Name', '')

            if is_empty(p.title):
                logger.error('Empty name for program "{0}", program ignored'.
                             format(p.name))
                p.missing_desktop = True
                continue

        if p.description is None:
            key = 'Comment[' + SETTINGS.language + ']'

            # Accept *ONLY* localized comments
            if key in entry:
                p.description = entry[key]

                if is_empty(p.description):
                    logger.warn('Empty comment specified for program "{0}" in '
                                'the .desktop file "{1}"'.
                                format(p.name, dd_name))
                    p.comment = None

        if is_empty(p.keywords):
            key = 'Keywords[' + SETTINGS.language + ']'

            # Accept *ONLY* localized keyword strings
            if key in entry:
                p.keywords = list(filter(None, entry[key].split(";")))

        if p.icon is None:
            if 'Icon' not in entry:
                logger.warn('Program "{0}" has no icon defined for it in the '
                            '.desktop file "{1}"'.format(p.name, dd_name))
            else:
                p.icon = entry.get('Icon', '')

        if is_empty(p.icon):
            logger.warn('Program "{0}" has an empty/invalid icon name, will '
                        'display incorrectly'.format(p.name))
            p.icon = None

        if p.command is None:
            if 'Exec' not in entry or is_empty(entry['Exec']):
                logger.warn('Program "{0}" has an empty or missing "Exec" '
                            'line in the desktop file "{1}", program ignored'.
                            format(p.name, dd_name))
                p.missing_desktop = True
                continue

            # Remove %XX parameters from the Exec key in the same way
            # Webmenu does it. It has worked fine for Webmenu, maybe
            # it works fine for us too...?
            # (Reference: file parts/webmenu/src/parseExec.coffee, line 24)
            import re
            p.command = re.sub(r"%[fFuUdDnNickvm]{1}", "", entry['Exec'])


    # Detect icon types
    for i in programs:
        p = programs[i]

        if p.hidden or p.icon is None:
            continue

        # Is the icon name a full path to an icon file, or just
        # a generic name?
        _, ext = split_ext(p.icon)

        if not is_empty(ext) and ext in ICON_EXTENSIONS:
            p.icon_is_path = True

    end_time = time.clock()
    logger.print_time('Desktop file parsing', start_time, end_time)

    # --------------------------------------------------------------------------
    # Step 3: Convert textual references into actual object references and
    # build the final menu data. Also mark used programs and menus while
    # we're at it.

    start_time = time.clock()

    for m in menus:
        menu = menus[m]

        if menu.hidden:
            continue

        new_programs = []

        for p in menu.programs:
            if p in programs:
                if programs[p].missing_desktop:
                    # Silently ignore desktop programs with missing
                    # .desktop files.
                    continue

                if not programs[p].hidden:
                    new_programs.append(programs[p])
                    programs[p].used = True
            else:
                logger.error('Menu "{0}" references to a non-existent '
                             'program "{1}"'.format(m, p))

        menu.programs = new_programs

    for c in categories:
        cat = categories[c]

        if cat.hidden:
            continue

        new_menus = []
        new_programs = []

        for m in cat.menus:
            if m in menus:
                if not menus[m].hidden:
                    new_menus.append(menus[m])
                    menus[m].used = True
            else:
                logger.error('Category "{0}" references to a non-existent '
                             'menu "{1}"'.format(c, m))

        for p in cat.programs:
            if p in programs:
                if programs[p].missing_desktop:
                    # silently ignore desktop programs with missing
                    # .desktop files
                    continue

                if not programs[p].hidden:
                    new_programs.append(programs[p])
                    programs[p].used = True
            else:
                logger.error('Category "{0}" references to a non-existent '
                             'program "{1}"'.format(c, p))

        cat.menus = new_menus
        cat.programs = new_programs

    # Remove desktop prorgams with .desktop files that could not be loaded.
    # This is done here so that we don't complain about "missing" programs
    # above when trying to find programs with broken .desktop files. These
    # programs exist, they just cannot be used.
    programs = {k: v for k, v in programs.items() if not programs[k].missing_desktop}

    # Warn about unused (and unhidden) programs, they just take up resources
    num_used_programs = 0
    num_used_menus = 0
    num_used_categories = 0

    for i in programs:
        p = programs[i]

        if not p.hidden and not p.used:
            logger.warn('Program "{0}" defined but not used'.format(p.name))

        if p.used and not p.hidden:
            num_used_programs += 1

    for i in menus:
        m = menus[i]

        if not m.hidden and not m.used:
            logger.warn('Menu "{0}" defined but not used'.format(m.name))

        if m.used and not m.hidden:
            num_used_menus += 1

    for i in categories:
        c = categories[i]

        if not c.hidden:
            num_used_categories += 1

    # Finally remove all hidden items
    programs = {k: v for k, v in programs.items() if not programs[k].hidden}
    menus = {k: v for k, v in menus.items() if not menus[k].hidden}
    categories = {k: v for k, v in categories.items() if not categories[k].hidden}

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
    logger.print_time('Menu data building time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Done

    logger.info(
        'Have {n_progs} programs ({n_used_progs} actually used), '
        '{n_menus} menus ({n_used_menus} actually used) and '
        '{n_cats} categories ({n_used_cats} actually used)'.
        format(n_progs=len(programs), n_used_progs=num_used_programs,
               n_menus=len(menus), n_used_menus=num_used_menus,
               n_cats=len(categories), n_used_cats=num_used_categories))

    end_time = time.clock()
    logger.print_time('Total menu parsing time',
                      total_start, end_time)

    return programs, menus, categories, category_index
