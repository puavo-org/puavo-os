# .desktop file parser. There are modules for this, but I want to keep
# the number of required external dependencies as little as possible.

import logging


def load(filename):
    """Fairly robust .desktop file parser. Tries to extract as much
    valid data as possible, returns dicts within dicts.

    Reference: https://standards.freedesktop.org/desktop-entry-spec/latest/
    Referenced: 2020-05-06."""

    section = None
    data = {}

    with open(filename, mode='r', encoding='utf-8') as inf:
        for line in inf.readlines():
            line = line.strip()

            if not line or line[0] == '#':
                continue

            if line[0] == '[' and line[-1] == ']':  # [section name]
                sect_name = line[1:-1].strip()

                if not sect_name:
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
                    if not key:
                        continue

                    # pylint: disable=unsupported-membership-test
                    if key in section:
                        # The spec does, however, say that keys within a section
                        # must be unique
                        logging.warning('Desktop file "%s" contains duplicate '
                                        'keys ("%s") within the same section',
                                        filename, key)
                        continue

                    # pylint: disable=unsupported-assignment-operation
                    section[key] = value

    return data
