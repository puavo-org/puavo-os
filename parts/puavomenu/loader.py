# Functions to load various menudata YAML and .desktop files and
# turn them into usable menu data.

import os.path
import logging
import re

from constants import PROGRAM_TYPE_DESKTOP, \
                      PROGRAM_TYPE_CUSTOM, \
                      PROGRAM_TYPE_WEB, \
                      ICON_EXTENSIONS, \
                      LANGUAGES
from menudata import Program, Menu, Category
import utils
import conditionals
from settings import SETTINGS


# Characters that can be used in program, menu and category IDs.
# For desktop programs, these IDs are also filenames, so anything
# that's allowed in filenames, must also be allowed here.
# Within reason, of course.
ALLOWED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' \
                'abcdefghijklmnopqrstuvwxyz' \
                '0123456789' \
                '._-'


# ------------------------------------------------------------------------------
# Utility


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


# ------------------------------------------------------------------------------
# Parsers


def __load_multilanguage_string(where):
    out = {}

    if isinstance(where, str):
        # Just one string, use it for all languages
        for lang in LANGUAGES:
            out[lang] = where
    else:
        # Load strings only for those languages that exist,
        # because otherwise, when we merge the, dictionaries,
        # "None" entries will overwrite not-None strings and
        # that's the opposite of what we want (permit partial/
        # complete overrides in YAML files).
        for lang in LANGUAGES:
            if lang in where:
                out[lang] = where[lang]

    return out


def load_menudata_yaml_file(filename):
    import yaml

    programs = {}
    menus = {}
    categories = {}

    with open(filename, mode='r', encoding='utf-8') as inf:
        # use safe_load(), it does not attempt to construct Python classes
        data = yaml.safe_load(inf.read())

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

    for node in data['programs']:
        status, menudata_id, params = __convert_yaml_node(node)

        if not status:
            continue

        if not __is_valid(menudata_id):
            logging.error('Program ID "%s" contains invalid characters, '
                          'program ignored', menudata_id)
            continue

        if menudata_id in programs:
            logging.warning('Program ID "%s" defined multiple times, ignoring '
                            'duplicates', menudata_id)
            continue

        # "Reserve" the name so it's used even if we can't parse this
        # program definition, otherwise duplicate entries might slip
        # through
        programs[menudata_id] = None

        # Figure out the type
        program_type = str(params.get('type', 'desktop'))

        if program_type not in ('desktop', 'custom', 'web'):
            logging.error('Unknown program type "%s" for "%s", '
                          'ignoring definition', program_type, menudata_id)
            continue

        program = {}

        # The default
        program['type'] = PROGRAM_TYPE_DESKTOP

        if program_type == 'desktop':
            program['type'] = PROGRAM_TYPE_DESKTOP
        elif program_type == 'custom':
            program['type'] = PROGRAM_TYPE_CUSTOM
        else:
            program['type'] = PROGRAM_TYPE_WEB

        if 'condition' in params:
            program['condition'] = str(params['condition'])

        if 'hidden_by_default' in params:
            program['hidden'] = bool(params['hidden_by_default'])

        if 'tags' in params:
            program['tags'] = set()

            for tag in __parse_list(params['tags']):
                stag = str(tag)

                if len(stag) > 0:
                    program['tags'].add(stag.lower())

        if 'keywords' in params:
            program['keywords'] = set()

            for word in __parse_list(params['keywords']):
                kwd = str(word)

                if len(kwd) > 0:
                    program['keywords'].add(kwd.lower())

        if 'name' in params:
            program['name'] = __load_multilanguage_string(params['name'])

        if 'description' in params:
            program['description'] = __load_multilanguage_string(params['description'])

        if 'icon' in params:
            program['icon'] = str(params['icon'])

        if 'command' in params and program['type'] in (PROGRAM_TYPE_DESKTOP, PROGRAM_TYPE_CUSTOM):
            program['command'] = str(params['command'])

        if 'url' in params and program['type'] == PROGRAM_TYPE_WEB:
            # Technically, it is a command...
            program['command'] = str(params['url'])

        programs[menudata_id] = program

    # --------------------------------------------------------------------------
    # Parse menus

    for node in data['menus']:
        status, menudata_id, params = __convert_yaml_node(node)

        if not status:
            continue

        if not __is_valid(menudata_id):
            logging.error('Menu ID "%s" contains invalid characters, '
                          'ignoring', menudata_id)
            continue

        if menudata_id in menus:
            logging.error('Menu ID "%s" defined multiple times, ignoring '
                          'duplicates', menudata_id)
            continue

        menu = {}

        if 'condition' in params:
            menu['condition'] = str(params['condition'])

        if 'hidden_by_default' in params:
            menu['hidden'] = bool(params['hidden_by_default'])

        if 'name' in params:
            menu['name'] = __load_multilanguage_string(params['name'])

        if 'description' in params:
            menu['description'] = __load_multilanguage_string(params['description'])

        if 'icon' in params:
            menu['icon'] = str(params['icon'])

        if 'programs' in params:
            menu['programs'] = __parse_list(params['programs'])

        menus[menudata_id] = menu

    # --------------------------------------------------------------------------
    # Parse categories

    for node in data['categories']:
        status, menudata_id, params = __convert_yaml_node(node)

        if not status:
            continue

        if not __is_valid(menudata_id):
            logging.error('Category ID "%s" contains invalid characters, '
                          'ignoring', menudata_id)
            continue

        if menudata_id in categories:
            logging.error('Category ID "%s" defined multiple times, ignoring '
                          'duplicates', menudata_id)
            continue

        category = {}

        if 'condition' in params:
            category['condition'] = str(params['condition'])

        if 'hidden_by_default' in params:
            category['hidden'] = bool(params['hidden_by_default'])

        if 'name' in params:
            category['name'] = __load_multilanguage_string(params['name'])

        if 'description' in params:
            category['description'] = __load_multilanguage_string(params['description'])

        if 'position' in params:
            # Will be validated later. For now, keep it as a string.
            category['position'] = str(params['position'])

        if 'menus' in params:
            category['menus'] = __parse_list(params['menus'])

        if 'programs' in params:
            category['programs'] = __parse_list(params['programs'])

        categories[menudata_id] = category

    return programs, menus, categories


def load_menudata_json_file(filename):
    """Loads menudata from a JSON file. The structure is almost identical to
    how data loaded from YAML files is actually kept in memory, so it's not
    difficult to convert raw JSON into usable menudata. In addition to that,
    JSON is *much* faster to parse than YAML. "Compiling" YAML files to JSON
    easily cuts 200-300 milliseconds from startup time, which is a visible
    speedup, even by eye.

    JSON's syntax is much stricter than YAML's, so we do only some basic
    validity checks. If Puavo one day gets the ability to supply extra
    menudata JSON files to Puavomenu, then this loader must be made to
    do extra validation."""

    import json

    programs = {}
    menus = {}
    categories = {}

    # There's a *LOT* less error handling here, compared to YAML loading.
    # JSON files are usually produced by us, so we'll assume they're
    # (mostly) error-free.

    # AFAIK it's not possible to have duplicate keys in a dict/hash
    # in JSON files, so there are no dupe checks here.

    with open(filename, mode='r', encoding='utf-8') as inf:
        data = json.load(inf)

    if data is None or not isinstance(data, dict):
        logging.warning('load_json_file(): got no data, or the data is not a dict')
        return {}, {}, {}

    if 'programs' in data:
        for name, src_program in data['programs'].items():
            if not __is_valid(name):
                logging.error('JSON program name "%s" contains invalid characters',
                              name)
                continue

            if ('type' not in src_program) or \
                    (src_program['type'] not in \
                        (PROGRAM_TYPE_DESKTOP,
                         PROGRAM_TYPE_CUSTOM,
                         PROGRAM_TYPE_WEB)):
                logging.error('JSON program "%s" has no type or the specified type is invalid',
                              name)
                continue

            dst_program = dict(src_program)

            # Convert lists back to sets
            if 'keywords' in dst_program:
                dst_program['keywords'] = set(dst_program['keywords'])

            if 'tags' in dst_program:
                dst_program['tags'] = set(dst_program['tags'])

            programs[name] = dst_program

    if 'menus' in data:
        for name, src_menu in data['menus'].items():
            if not __is_valid(name):
                logging.error('JSON menu name "%s" contains invalid characters',
                              name)
                continue

            menus[name] = dict(src_menu)

    if 'categories' in data:
        for name, src_cat in data['categories'].items():
            if not __is_valid(name):
                logging.error('JSON category name "%s" contains invalid characters',
                              name)
                continue

            categories[name] = dict(src_cat)

    return programs, menus, categories


def save_menudata_json_file(filename, programs, menus, categories):
    """Used to convert, or "compile", YAML files to JSON. JSON is faster to
    load, and for once its much more strict syntax works well, because we
    have to do less validation for JSON data than for YAML data."""

    # Handle errors internally, don't let them escape this function.
    # There's another exception handler around the block where this
    # is called from, but that is used to report failed YAML loading
    # and we don't want errors happening in this function to end up
    # in there. Log the error, but do nothing else.
    try:
        import json

        data = {}
        data['programs'] = {}
        data['menus'] = {}
        data['categories'] = {}

        # The default JSON serializer doesn't grok sets, so convert them
        # to lists. To do this, we must manually go through the programs.
        for name, program in programs.items():
            pd = dict(program)

            if 'keywords' in pd:
                pd['keywords'] = list(pd['keywords'])

            if 'tags' in pd:
                pd['tags'] = list(pd['tags'])

            data['programs'][name] = pd

        # Menus and categories should work as-is
        if len(menus) > 0:
            data['menus'] = menus

        if len(categories) > 0:
            data['categories'] = categories

        with open(filename, mode='w', encoding='utf-8') as out:
            json.dump(data, out)
    except Exception as exception:
        logging.error('Could not save file "%s": %s', filename, str(exception))


def load_dotdesktop_file(filename):
    """Fairly robust .desktop file parser. Tries to extract as much
    valid data as possible, returns dicts within dicts.

    Reference: https://standards.freedesktop.org/desktop-entry-spec/latest/
    Referenced: 2017-07-25."""

    section = None
    data = {}

    with open(filename, mode='r', encoding='utf-8') as inf:
        for line in inf.readlines():
            line = line.strip()

            if utils.is_empty(line) or line[0] == '#':
                continue

            if line[0] == '[' and line[-1] == ']':  # [section name]
                sect_name = line[1:-1].strip()

                if utils.is_empty(sect_name):
                    # Nothing in the spec says that empty section names are
                    # invalid, but what on Earth would we do with them?
                    logging.warning('Desktop file "%s" contains an empty '
                                    'section name', filename)
                    section = None

                if sect_name in data:
                    # Section names must be unique
                    logging.warning('Desktop file "%s" contains a '
                                    'duplicate section', filename)
                    section = None

                data[sect_name] = {}
                section = data[sect_name]
            else:                                   # key=value
                equals = line.find('=')

                if equals != -1 and section is not None:
                    key = line[0:equals].strip()
                    value = line[equals+1:].strip()

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
                                        filename, key)
                        continue

                    section[key] = value

    return data


# ------------------------------------------------------------------------------
# Menudata builders


def load_dirs_config(name):
    import json

    desktop_dirs = []
    icon_dirs = []

    try:
        with open(name, 'r', encoding='utf-8') as f:
            dirs = json.load(f)

        if 'desktop_dirs' in dirs:
            desktop_dirs = dirs['desktop_dirs']

        if 'icon_dirs' in dirs:
            icon_dirs = dirs['icon_dirs']
    except Exception as exception:
        logging.fatal('Failed to load the directories config file "%s": %s',
                      name, str(exception))
        raise exception

    return desktop_dirs, icon_dirs


def parse_source_files(sources):
    raw_programs = {}
    raw_menus = {}
    raw_categories = {}

    for name in sources:
        try:
            logging.info('Loading menudata file "%s"...', name)

            if name.endswith('.json'):
                progs, menus, cats = load_menudata_json_file(name)
            elif name.endswith('.yml'):
                progs, menus, cats = load_menudata_yaml_file(name)
            else:
                logging.error('Unknown format in menudata file "%s"',
                              name)
                continue
        except Exception as exception:
            logging.error('Could not load file "%s": %s', name, str(exception))
            logging.error(exception, exc_info=True)
            continue

        # Program, menu and category IDs must be unique within a file, but
        # not across files; a file loaded later can replace earlier
        # definitions. This is by design.
        raw_programs.update(progs)
        raw_menus.update(menus)
        raw_categories.update(cats)

    return raw_programs, raw_menus, raw_categories


def compile_menudata_files(sources):
    for name in sources:
        json_name = os.path.splitext(name)[0] + '.json'

        logging.info('Compiling menudata file "%s" to "%s"...',
                     name, json_name)
        progs, menus, cats = load_menudata_yaml_file(name)
        save_menudata_json_file(json_name, progs, menus, cats)


def merge_dotdesktop_and_yaml_data(yaml_data, desktop_entry):
    # Load every item we don't *already* have. This allows YAML files
    # to partially (or completely) override .desktop files.

    # Load program names for languages we don't have yet
    temp = {}

    for lang in LANGUAGES:
        key = 'Name[' + lang + ']'

        if key not in desktop_entry:
            key = 'GenericName[' + lang + ']'

            if key not in desktop_entry:
                key = 'Name'

        if key in desktop_entry:
            temp[lang] = desktop_entry[key]

    if 'name' in yaml_data:
        temp.update(yaml_data['name'])

    yaml_data['name'] = temp

    # Repeat the above mess for descriptions (comments)
    temp = {}

    for lang in LANGUAGES:
        key = 'Comment[' + lang + ']'

        if key in desktop_entry:
            temp[lang] = desktop_entry[key]

    # Use "generic" English description if "en" description does
    # not exist. Yes, this is a hack.
    if 'Comment' in desktop_entry and 'en' not in temp:
        temp['en'] = desktop_entry['Comment']

    if 'description' in yaml_data:
        temp.update(yaml_data['description'])

    yaml_data['description'] = temp

    # Extract search keywords
    temp = {}

    for lang in LANGUAGES:
        key = 'Keywords[' + lang + ']'

        if key not in desktop_entry:
            key = 'Keywords'

        if key in desktop_entry:
            temp[lang] = set(filter(None, desktop_entry[key].split(";")))
        else:
            temp[lang] = set()

        # TODO: Per-language keywords in YAML files
        if 'keywords' in yaml_data:
            temp[lang].update(yaml_data['keywords'])

    yaml_data['keywords'] = temp

    # Get the icon name. These can be localised too, but we ignore that.
    if ('icon' not in yaml_data) and ('Icon' in desktop_entry):
        yaml_data['icon'] = str(desktop_entry['Icon'])

    # Command line / URL
    if ('command' not in yaml_data) and ('Exec' in desktop_entry):
        yaml_data['command'] = str(desktop_entry['Exec'])

    # Store categories as tags
    if 'Categories' in desktop_entry:
        tags = set()

        # Annoyingly, .desktop files use semicolons here,
        # but we use just spaces/commas
        for raw_cat in filter(None, desktop_entry['Categories'].split(';')):
            cat = raw_cat.strip()

            if len(cat) > 0:
                tags.add(cat.lower())

        if len(tags) > 0:
            if 'tags' in yaml_data:
                yaml_data['tags'].update(tags)
            else:
                yaml_data['tags'] = tags


def load_desktop_files(desktop_dirs, raw_programs):
    for menudata_id, program in raw_programs.items():
        if not program or program['type'] != PROGRAM_TYPE_DESKTOP:
            continue

        # Locate the .desktop file
        desktop_file = None

        for dir_name in desktop_dirs:
            full = os.path.join(dir_name, menudata_id + '.desktop')

            if os.path.isfile(full):
                desktop_file = full
                break

        if desktop_file is None:
            logging.error('.desktop file for program "%s" not found',
                          menudata_id)

            # This program is broken, clear its slot so we won't touch
            # it again
            raw_programs[menudata_id] = None
            continue

        # Try to load it
        try:
            desktop_data = load_dotdesktop_file(desktop_file)
        except Exception as exception:
            logging.error('Could not load file "%s" for program "%s": %s',
                          desktop_file, menudata_id, str(exception))
            raw_programs[menudata_id] = None
            continue

        if 'Desktop Entry' not in desktop_data:
            logging.error('Rejecting desktop file "%s" for "%s": No "[Desktop Entry]" '
                          'section in the file', desktop_file, menudata_id)
            raw_programs[menudata_id] = None
            continue

        # Load the parts from the .desktop file we don't have yet
        merge_dotdesktop_and_yaml_data(program, desktop_data['Desktop Entry'])


def apply_filters(raw_programs, raw_menus, raw_categories, conditions, filters):
    from tags_filter import Action

    # Conditions first...
    for menudata_id, program in raw_programs.items():
        if program and ('condition' in program) and program['condition'] and \
            conditionals.is_hidden(conditions, program['condition'],
                                   menudata_id, 'Program'):
            program['hidden'] = True

    for menudata_id, menu in raw_menus.items():
        if menu and ('condition' in menu) and (menu['condition']) and \
            conditionals.is_hidden(conditions, menu['condition'], menudata_id,
                                   'Menu'):
            menu['hidden'] = True

    for menudata_id, cat in raw_categories.items():
        if cat and ('condition' in cat) and (cat['condition']) and \
            conditionals.is_hidden(conditions, cat['condition'], menudata_id,
                                   'Category'):
            cat['hidden'] = True

    # ...then tags because they can override conditions (this is by design)
    if filters.have_data():
        # Filter programs
        for menudata_id, program in raw_programs.items():
            if not program:
                continue

            # All programs must have at least one tag, again by design
            if len(program['tags']) == 0:
                logging.warning('Program "%s" has no tags, hiding it', menudata_id)
                program['hidden'] = True
                continue

            lname = menudata_id.lower()

            for act in filters.actions:
                if act.target == Action.TAG:
                    if act.name not in program['tags']:
                        continue
                elif act.target == Action.PROGRAM:
                    if act.name != lname:
                        continue
                else:
                    continue

                if act.action == Action.SHOW:
                    program['hidden'] = False
                else:
                    program['hidden'] = True

        # Filter menus
        for menudata_id, menu in raw_menus.items():
            if not menu:
                continue

            if menudata_id not in filters.menu_names:
                continue

            lname = menudata_id.lower()

            for act in filters.actions:
                if (act.target != Action.MENU) or (act.name != lname):
                    continue

                if act.action == Action.SHOW:
                    menu['hidden'] = False
                else:
                    menu['hidden'] = True

        # Filter categories
        for menudata_id, cat in raw_categories.items():
            if not cat:
                continue

            if menudata_id not in filters.category_names:
                continue

            lname = menudata_id.lower()

            for act in filters.actions:
                if (act.target != Action.CATEGORY) or (act.name != lname):
                    continue

                if act.action == Action.SHOW:
                    cat['hidden'] = False
                else:
                    cat['hidden'] = True


def build_menu_data(raw_programs, raw_menus, raw_categories):
    programs = {}
    menus = {}
    categories = {}

    # Build programs
    for menudata_id, src_prog in raw_programs.items():
        if not src_prog:
            continue

        if not 'type' in src_prog:
            logging.error('Program "%s" has no type specified. '
                          'This really should not happen.', menudata_id)
            continue

        dst_prog = Program()

        # Type and menudata ID. Python, why did you have to reserve
        # common words as "type" and "id" and not let me use them?
        dst_prog.program_type = src_prog['type']
        dst_prog.menudata_id = menudata_id

        # We can't actually remove hidden things. as they are referenced
        # to in menus and categories and if we remove them here, we'll
        # erroneously report them to be "broken".
        if 'hidden' in src_prog and src_prog['hidden']:
            dst_prog.hidden = True

        # Name (required)
        if 'name' in src_prog and src_prog['name']:
            dst_prog.name = utils.localize(src_prog['name'])

        if utils.is_empty(dst_prog.name):
            logging.error('Program "%s" has no name at all, skipping it',
                          menudata_id)
            raw_programs[menudata_id] = None
            continue

        # Description (optional), accept ONLY a localized description
        if 'description' in src_prog and src_prog['description'] and \
               SETTINGS.language in src_prog['description']:
            dst_prog.description = utils.localize(src_prog['description'])

        # Keywords (optional)
        if 'keywords' in src_prog and SETTINGS.language in src_prog['keywords']:
            dst_prog.keywords = list(src_prog['keywords'][SETTINGS.language])

        # Command (required)
        if 'command' in src_prog:
            dst_prog.command = src_prog['command']

        if utils.is_empty(dst_prog.command):
            if dst_prog.program_type == PROGRAM_TYPE_WEB:
                logging.error('Web link "%s" has an empty or missing URL, '
                              'link ignored', menudata_id)
            else:
                logging.error('Program "%s" has an empty or missing command, '
                              'program ignored', menudata_id)

            raw_programs[menudata_id] = None
            continue

        if dst_prog.program_type in (PROGRAM_TYPE_DESKTOP, PROGRAM_TYPE_CUSTOM):
            # Remove the %XX parameters from the Exec key in the same way
            # Webmenu does it. It has worked fine for Webmenu, maybe
            # it works fine for us too...?
            # (Reference: file parts/webmenu/src/parseExec.coffee, line 24)
            # TODO: This is NOT okay. We could fairly easily fill in
            # the parameters with correct values. Plus, if the program
            # is added to the panel/desktop, we could, in some cases,
            # copy this filtered command line into the new desktop file,
            # which results in an icon that does not always work properly!
            dst_prog.command = re.sub(r"%[fFuUdDnNickvm]{1}", "", dst_prog.command)

        # Icon
        if 'icon' in src_prog:
            dst_prog.icon_name = src_prog['icon']

        if utils.is_empty(dst_prog.icon_name):
            logging.warning('Program "%s" has no icon defined for it',
                            menudata_id)
        else:
            # Is the icon name a full path to an icon file, or just
            # a generic name?
            _, ext = os.path.splitext(dst_prog.icon_name)

            if (not utils.is_empty(ext)) and (ext in ICON_EXTENSIONS):
                dst_prog.icon_name_is_path = True

        programs[menudata_id] = dst_prog

    # Build menus and add programs to them
    for menudata_id, src_menu in raw_menus.items():
        if not src_menu:
            continue

        dst_menu = Menu()

        dst_menu.menudata_id = menudata_id

        # Like programs, we only flag menus to be hidden
        if 'hidden' in src_menu and src_menu['hidden']:
            dst_menu.hidden = True

        # Name (required)
        if 'name' in src_menu and src_menu['name']:
            dst_menu.name = utils.localize(src_menu['name'])

        if utils.is_empty(dst_menu.name):
            logging.error('Menu "%s" has no name at all, skipping it',
                          menudata_id)
            raw_menus[menudata_id] = None
            continue

        # Description (optional)
        if 'description' in src_menu and src_menu['description']:
            dst_menu.description = utils.localize(src_menu['description'])

        # Icon (required, but it's not fatal if it's missing)
        if 'icon' in src_menu and src_menu['icon']:
            dst_menu.icon_name = src_menu['icon']

        if utils.is_empty(dst_menu.icon_name):
            logging.warning('Menu "%s" has no icon defined for it',
                            menudata_id)

        # List of programs (required, but it's not fatal if it's empty/missing)
        had_something = False

        if 'programs' in src_menu:
            for p_name in src_menu['programs']:
                if p_name not in programs or programs[p_name] is None:
                    logging.warning('Menu "%s" references to a non-existent program "%s"',
                                    menudata_id, p_name)
                    continue

                # Don't whine about an empty menu if all of it's programs
                # are hidden
                had_something = True

                # Silently ignore hidden programs
                if programs[p_name].hidden:
                    continue

                programs[p_name].used = True
                dst_menu.programs.append(programs[p_name])

        if len(dst_menu.programs) == 0 and not had_something:
            logging.warning('Menu "%s" is completely empty', menudata_id)

        menus[menudata_id] = dst_menu

    # Build categories and add menus and programs to them
    for menudata_id, src_cat in raw_categories.items():
        if not src_cat:
            continue

        if 'hidden' in src_cat and src_cat['hidden']:
            continue

        dst_cat = Category()

        dst_cat.menudata_id = menudata_id

        # Name (required)
        if 'name' in src_cat and src_cat['name']:
            dst_cat.name = utils.localize(src_cat['name'])

        if utils.is_empty(dst_cat.name):
            logging.error('Category "%s" has no name at all, skipping it',
                          menudata_id)
            raw_categories[menudata_id] = None
            continue

        # Description (optional)
        if 'description' in src_cat and src_cat['description']:
            dst_cat.description = utils.localize(src_cat['description'])

        # List of menus and programs (technically you need at least one of
        # either, but it's not a fatal error to omit everything, it just
        # looks ugly)
        if 'menus' in src_cat:
            for m_name in src_cat['menus']:
                if m_name not in menus or menus[m_name] is None:
                    logging.warning('Category "%s" references to a non-existent menu "%s"',
                                    menudata_id, m_name)
                    continue

                # Silently ignore hidden menus
                if menus[m_name].hidden:
                    continue

                menus[m_name].used = True
                dst_cat.menus.append(menus[m_name])

        if 'programs' in src_cat:
            for p_name in src_cat['programs']:
                if p_name not in programs or programs[p_name] is None:
                    logging.warning('Category "%s" references to a non-existent program "%s"',
                                    menudata_id, p_name)
                    continue

                # Silently ignore hidden programs
                if programs[p_name].hidden:
                    continue

                programs[p_name].used = True
                dst_cat.programs.append(programs[p_name])

        # Position
        if 'position' in src_cat:
            try:
                dst_cat.position = int(src_cat['position'])
            except ValueError:
                logging.warning('Cannot interpret "%s" as a position for '
                                'category "%s", defaulting to 0',
                                src_cat['position'], menudata_id)
                dst_cat.position = 0

        if len(dst_cat.menus) == 0 and len(dst_cat.programs) == 0:
            logging.warning('Category "%s" is completely empty', menudata_id)

        categories[menudata_id] = dst_cat

    return programs, menus, categories


def sort_categories(categories):
    # Sort the categories by position, but if the positions are identical,
    # sort by names. Warning: the sort is not locale-aware or case
    # insensitive!
    index = []

    for menudata_id, cat in categories.items():
        if not cat.hidden:
            index.append((cat.position, menudata_id))

    index.sort(key=lambda cat: (cat[0], cat[1]))

    return [i[1] for i in index]


def load_icons(programs, menus, icon_dirs):
    from iconcache import ICONS48

    # Multiple programs can use the same generic icon name.
    # The IconCache class prevents us from loading multiple
    # copies of the same image, but this prevents us from
    # searching for the same generic icon multiple times.
    generic_name_cache = {}

    num_missing_icons = 0

    # Programs first
    for menudata_id, program in programs.items():
        if program.hidden:
            continue

        if program.icon_name is None:
            # This should not happen, ever
            logging.error('The impossible happened: program "%s" '
                          'has no icon at all!', menudata_id)
            num_missing_icons += 1
            continue

        if (not program.icon_name_is_path) and \
                program.icon_name in generic_name_cache:
            # Reuse a cached generic icon
            program.icon_name = generic_name_cache[program.icon_name]
            program.icon_name_is_path = True

        if program.icon_name_is_path:
            # Just load it
            if os.path.isfile(program.icon_name):
                icon = ICONS48.load_icon(program.icon_name)

                if icon.usable:
                    program.icon = icon
                    continue

            # An icon file was specified, but it could not be loaded.
            # Sometimes icon names contain an extension (ie. "name.png")
            # that confuses our autodetection. Unless the icon name really
            # is a full path + filename, try to locate the correct image.
            if len(os.path.dirname(program.icon_name)) > 0:
                logging.error('Could not load icon "%s" for program "%s"',
                              program.icon_name, menudata_id)
                num_missing_icons += 1
                continue

        # Search for the generic icon
        icon_path = None

        for dir_name in icon_dirs:
            # Try the name as-is first (see above, some icons don't have
            # a path in their names, but they have an extension)
            candidate = os.path.join(dir_name, program.icon_name)

            if os.path.isfile(candidate):
                icon_path = candidate
                break

            # Try different extensions
            for ext in ICON_EXTENSIONS:
                candidate = os.path.join(dir_name,
                                         program.icon_name + ext)

                if os.path.isfile(candidate):
                    icon_path = candidate
                    break

            if icon_path:
                break

        if not icon_path:
            logging.error('Icon "%s" for program "%s" not found in '
                          'icon load paths', program.icon_name, menudata_id)
            num_missing_icons += 1
            continue

        program.icon = ICONS48.load_icon(icon_path)

        if not program.icon.usable:
            logging.warning('Found icon "%s" for program "%s", but '
                            'it could not be loaded', icon_path, menudata_id)
            num_missing_icons += 1
        else:
            if not program.icon_name_is_path:
                # Cache the generic icon name
                generic_name_cache[program.icon_name] = icon_path

        program.icon_name = icon_path
        program.icon_name_is_path = True

    # Then menus. This is much simpler, because menu icons
    # must always be full paths. No automagic here.
    for menu_id, menu in menus.items():
        if menu.hidden:
            continue

        if menu.icon_name is None:
            logging.warning('Menu "%s" has no icon defined', menu_id)
            num_missing_icons += 1
            continue

        if not os.path.isfile(menu.icon_name):
            logging.error('Icon "%s" for menu "%s" does not exist',
                          menu.icon_name, menu_id)
            menu.icon = None
            num_missing_icons += 1
            continue

        menu.icon = ICONS48.load_icon(menu.icon_name)

        if not menu.icon.usable:
            logging.warning('Found an icon "%s" for menu "%s", but '
                            'it could not be loaded', menu.icon_name, menu_id)
            num_missing_icons += 1

    if num_missing_icons:
        logging.info('Have %d missing or unloadable icons',
                     num_missing_icons)

    stats = ICONS48.stats()

    logging.info('Number of 48-pixel icons cached: %d (out of %d)',
                 stats['num_icons'], stats['capacity'])

    logging.info('Number of 48-pixel atlas surfaces: %d',
                 stats['num_atlases'])


# ------------------------------------------------------------------------------


MENU_FILE_PATTERN = re.compile(r'^\d\d')


def find_menu_files(*where):
    import glob
    import os

    files = []

    for full_name in glob.iglob(os.path.join(*where, '*.yml')):
        name = os.path.basename(full_name)
        number = MENU_FILE_PATTERN.search(name)

        if number:
            # The first two elements are for sorting (numbers first, then
            # names), the third element is the actual name you want to use
            # after sorting.
            files.append((number.group(0), name[number.end(0):], full_name))

    return files


def sort_menu_files(files):
    """Sort the filename tuples and return a list of just filenames.
    So if you have this:

        [
            ('51', '-fixes.yml', 'foo/bar/51-fixes.yml')
            ('50', '-default.yml', 'foo/bar/50-default.yml'),
        ]

    Then this function will return you this:

        ['foo/bar/50-default.yml', 'foo/bar/51-fixes.yml']
    """

    return [name[2] for name in sorted(files, key=lambda i: (i[0], i[1]))]


def find_json_replacements(files):
    """Finds suitable JSON replacements for YAML files, if they exist."""

    for index, name in enumerate(files):
        # If there's a similarly-named JSON file that's newer (or equally
        # old) than the YAML, load it instead.
        json_name = os.path.splitext(name)[0] + '.json'

        if not os.path.isfile(json_name):
            continue

        if os.path.getmtime(json_name) < os.path.getmtime(name):
            continue

        files[index] = json_name


def load_menu_data(root_dir, filter_string):
    """The main menu loader function. Call this."""

    import time

    total_start = time.clock()

    # --------------------------------------------------------------------------
    # Load the paths config file

    desktop_dirs, icon_dirs = load_dirs_config(os.path.join(root_dir, 'dirs.json'))

    # ----------------------------------------------------------------------
    # Get a list of all available condition and menudata files

    start_time = time.clock()

    condition_files = sort_menu_files(find_menu_files(root_dir, 'conditions'))
    menudata_files = sort_menu_files(find_menu_files(root_dir, 'menudata'))

    if not SETTINGS.compile_mode:
        # Don't "recompile" existing files!
        find_json_replacements(menudata_files)

    end_time = time.clock()

    utils.log_elapsed_time('Condition and menudata files scanning time',
                           start_time, end_time)

    # --------------------------------------------------------------------------
    # Load and evaluate conditions

    if not SETTINGS.compile_mode:
        start_time = time.clock()

        logging.info('Have %d source(s) for conditions', len(condition_files))

        conditions = {}

        for name in condition_files:
            conditions.update(conditionals.evaluate_file(name))

        end_time = time.clock()

        utils.log_elapsed_time('Conditions evaluation time',
                               start_time, end_time)

    # --------------------------------------------------------------------------
    # Load tag filters

    if not SETTINGS.compile_mode:
        start_time = time.clock()

        from tags_filter import Filter

        tag_filter = Filter(filter_string)

        end_time = time.clock()

        utils.log_elapsed_time('Tag filter load time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Parse all available menudata files

    start_time = total_start

    logging.info('Have %d source(s) for menu data', len(menudata_files))

    if SETTINGS.compile_mode:
        logging.info('Compiling all available YAML files to JSON')
        compile_menudata_files(menudata_files)
        logging.info('Compilation done')
        return {}, {}, {}, []

    raw_programs, raw_menus, raw_categories = parse_source_files(menudata_files)

    end_time = time.clock()

    utils.log_elapsed_time('YAML loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Locate and load .desktop files for desktop programs

    start_time = time.clock()

    if utils.is_empty(desktop_dirs):
        logging.warning('No .desktop file search paths specified!')

    load_desktop_files(desktop_dirs, raw_programs)

    end_time = time.clock()

    utils.log_elapsed_time('Desktop file loading time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Apply conditions and tag filters

    start_time = time.clock()

    apply_filters(raw_programs, raw_menus, raw_categories, conditions, tag_filter)

    end_time = time.clock()

    utils.log_elapsed_time('Filtering time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Build actual program, menu and category objects and build
    # the actual menu structure

    start_time = time.clock()

    programs, menus, categories = \
        build_menu_data(raw_programs, raw_menus, raw_categories)

    category_index = sort_categories(categories)

    end_time = time.clock()

    utils.log_elapsed_time('Menu building time', start_time, end_time)

    # --------------------------------------------------------------------------
    # Locate and load icons for programs and menus

    logging.info('Loading icons...')

    start_time = time.clock()

    load_icons(programs, menus, icon_dirs)

    end_time = time.clock()

    utils.log_elapsed_time('Icon loading time', start_time, end_time)

    # --------------------------------------------------------------------------

    # Useful little statistics
    num_used_programs = 0
    num_used_menus = 0
    num_used_categories = 0

    for _, program in programs.items():
        if not program.hidden:
            num_used_programs += 1

    for _, menu in menus.items():
        if not menu.hidden:
            num_used_menus += 1

    for _, cat in categories.items():
        if not cat.hidden:
            num_used_categories += 1

    logging.info(
        'Have %d programs (%d actually used), '
        '%d menus (%d actually used) and '
        '%d categories (%d actually used)',
        len(programs), num_used_programs,
        len(menus), num_used_menus,
        len(categories), num_used_categories)

    end_time = time.clock()

    utils.log_elapsed_time('Total menudata load time', total_start, end_time)

    return programs, menus, categories, category_index
