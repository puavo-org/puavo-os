# PuavoMenu miscellaneous utility functions

import logger


def localize(where, lang_id):
    """Given a string/list/dict and a key, looks up a localized string
    using the key."""

    if where is None:
        logger.error('localize(): "where" is None, nothing to localize!')
        return '[ERROR]'

    if isinstance(where, str):
        # just one string, nothing to localize, use it as-is
        return where
    elif isinstance(where, list):
        # a list of dicts, merge them
        where = {k: v for p in where for k, v in p.items()}

    if lang_id in where:
        # have a localized string, use it
        return str(where[lang_id])

    if 'en' in where:
        # no localized string available; try English, it's the default
        return str(where['en'])

    # it's a list with only one entry and it's not the language
    # we want, but we have to use it anyway
    logger.warn('localize(): missing localization for "{0}" in "{1}"'.
                format(lang_id, where))

    return str(where[list(where)[0]])


def is_empty(string):
    """Returns true if 's' is completely empty. This ugly hacky function
    is needed because YAML."""

    return string is None or len(string) == 0


def get_file_contents(name, default=''):
    """Reads the contents of a UTF-8 file into a buffer."""

    try:
        return open(name, 'r', encoding='utf-8').read().strip()
    except OSError as exception:
        logger.error('Could not load file "{0}": {1}'.format(name, exception))
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
