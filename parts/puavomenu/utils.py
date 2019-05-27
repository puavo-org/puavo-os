# PuavoMenu miscellaneous utility functions

import logging
from collections import OrderedDict


def localize(where, lang):
    """Given a string/list/dict, looks up a localized string using the
    current language."""

    if where is None:
        logging.error('localize(): "where" is None, nothing to localize!')
        return '[ERROR]'

    if isinstance(where, str):
        # just one string, nothing to localize, use it as-is
        return where
    elif isinstance(where, list):
        # a list of dicts, merge them
        where = {k: v for p in where for k, v in p.items()}

    if lang in where:
        # have a localized string, use it
        return str(where[lang])

    if 'en' in where:
        # no localized string available; try English, it's the default
        return str(where['en'])

    # it's a list with only one entry and it's not the language
    # we want, but we have to use it anyway
    logging.warning('localize(): missing localization for "%s" in "%s"',
                    lang, where)

    return str(where[list(where)[0]])


def is_empty(string):
    """Returns true if 's' is completely empty. This ugly hacky function
    is needed because YAML."""

    return string is None or len(string) == 0


def dedupe_list(seq):
    """Deduplicates a list while retaining item order. Tested only with lists
    of strings."""
    return list(OrderedDict.fromkeys(seq))


def get_file_contents(name, default=''):
    """Reads the contents of a UTF-8 file into a buffer."""

    try:
        return open(name, 'r', encoding='utf-8').read().strip()
    except OSError as exception:
        logging.error('Could not load file "%s": %s', name, str(exception))
        return default


def expand_variables(string, variables=None):
    """Expands "$(name)" variables in a string."""

    if not isinstance(string, str):
        return string

    if not isinstance(variables, dict):
        return string

    start = 0
    out = ''

    while True:
        # find the next token start
        pos = string.find('$(', start)

        if pos == -1:
            # no more tokens, copy the remainder
            out += string[start:]
            break

        # find the token end
        end = string.find(')', pos + 2)

        if end == -1:
            # not found, copy as-is
            out += string[start:]
            break

        out += string[start:pos]

        # expand the token if possible
        token = string[pos+2:end]

        if len(token) == 0 or token not in variables:
            out += string[pos:end+1]
        else:
            out += variables[token]

        start = end + 1

    return out


def puavo_conf(name, default):
    """puavo-conf call with a default value that is returned if
    the call fails."""

    try:
        import subprocess

        proc = subprocess.Popen(['puavo-conf', name],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
        proc.wait()

        if proc.returncode == 1:
            # Assume the value does not exist. We cannot distinguish
            # between failed puavo-conf calls and unknown/mistyped
            # puavoconf variables.
            return default

        return proc.stdout.read().decode('utf-8').strip()
    except Exception as exception:
        logging.error('puavo_conf() failed with name="%s", '
                      'returning default "%s":', name, default)
        logging.error(str(exception))
        return default


def log_elapsed_time(title, start_ms, end_ms):
    logging.info('%s: %s milliseconds',
                 title,
                 '{0:.1f}'.format((end_ms - start_ms) * 1000.0))
