# Conditional evaluators

from os.path import exists as path_exists, \
                    isfile as is_file, \
                    getsize as get_size

import os
import re
import stat

import logging

from utils import is_empty

# ------------------------------------------------------------------------------
# Evaluators

def __file_check(name, params):
    """Checks if a file exists/does not exist. Optional checks include
    size, hash and content checks."""

    state = path_exists(params['name'])
    present = params.get('present', True)

    if present == state:
        if present:
            # Make sure it's not a directory
            s = os.stat(params['name'])

            if stat.S_ISDIR(s.st_mode):
                return (True, False)

            # The file exists, do additional checks?
            if 'size' in params:
                # Check size
                size = int(params['size'])

                if size < 0:
                    logging.error('Negative file size specified in '
                                  'conditional "%s"', name)
                    return (False, False)

                if get_size(params['name']) != size:
                    return (True, False)

            if 'hash' in params:
                # SHA256 hash check
                if len(params['hash']) != 64:
                    logging.error('Invalid hash (wrong size) specified in '
                                  'conditional "%s"', name)
                    return (False, False)

                from hashlib import sha256
                h = sha256()

                with open(params['name'], 'rb') as f:
                    while True:
                        data = f.read(4096)

                        if len(data) == 0:
                            break

                        h.update(data)

                if params['hash'] != h.hexdigest():
                    return (True, False)

            if 'contents' in params:
                # raw contents check
                from base64 import b64encode

                if b64encode(open(params['name'], 'rb').read()) != \
                       bytes(params['contents'], 'ascii'):
                    return (True, False)

        return (True, True)

    return (True, False)


def __dir_check(name, params):
    """Checks if a directory exists/does not exist."""

    state = path_exists(params['name'])
    present = params.get('present', True)

    if present == state:
        if present:
            # It exists, make sure it really is a directory
            s = os.stat(params['name'])

            if not stat.S_ISDIR(s.st_mode):
                return (True, False)

        return (True, True)

    return (True, False)


def __env_var(name, params):
    """Checks that an environment variable has been defined (or not)
    and optionally checks its value."""

    state = True if params['name'] in os.environ else False
    present = params.get('present', True)

    if present == state:
        if present and 'value' in params:
            # content check
            wanted = params['value']
            got = os.environ[params['name']]

            logging.debug('env_var "%s": wanted="%s" got="%s" result=%r',
                          params['name'], wanted, got, wanted == got)

            if re.search(wanted, got) is None:
                return (True, False)

        return (True, True)

    return (True, False)


def __puavo_conf(name, params):
    """Puavo-conf variable presence (and optionally content) check."""

    import subprocess

    proc = subprocess.Popen(['puavo-conf', params['name']],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    proc.wait()

    state = True
    present = params.get('present', True)

    if proc.returncode == 1:
        # Assume the value does not exist. We cannot distinguish
        # between failed puavo-conf calls and unknown/mistyped
        # puavoconf variables.
        state = False

    if present == state:
        if 'value' in params:
            # content check
            wanted = params['value']
            got = proc.stdout.read().decode('utf-8').strip()

            logging.debug('puavo_conf "%s": wanted="%s" got="%s" result=%r',
                          params['name'], wanted, got, wanted == got)

            if re.search(wanted, got) is None:
                return (True, False)

        return (True, True)

    return (True, False)


def __constant(name, params):
    """Returns a constant true/false value. Defaults to true if no value
    has been specified. Used mostly in debugging/development."""

    return (True, bool(params.get('value', True)))


# List of known conditions and their evaluator functions
__FUNCTIONS = {
    'file_check': __file_check,
    'dir_check': __dir_check,
    'env_var': __env_var,
    'puavo_conf': __puavo_conf,
    'constant': __constant,
}


# ------------------------------------------------------------------------------


def evaluate_file(file_name):
    """Evaluates the conditionals listed in a file and returns their
    results in a dict."""

    logging.info('Loading a conditionals file "%s"', file_name)

    results = {}

    if not is_file(file_name):
        logging.error('File "%s" does not exist', file_name)
        return results

    try:
        from yaml import safe_load as yaml_safe_load
        data = yaml_safe_load(open(file_name, 'r', encoding='utf-8').read())
    except Exception as exception:
        logging.error(str(exception))
        return results

    for cond in (data or []):
        if 'name' not in cond:
            logging.error('Ignoring a conditional without a name '
                          '(missing the "name" key)')
            continue

        name = cond['name']

        if name in results:
            logging.error('Duplicate conditional "%s", skipping', name)
            continue

        if 'function' not in cond:
            logging.error('Conditional "%s" has no function defined, skipping',
                          name)
            continue

        function = cond['function']

        if function not in __FUNCTIONS:
            logging.error('Conditional "%s" has an unknown function "%s", '
                          'skipping', name, function)
            continue

        if ('params' not in cond) or (cond['params'] is None):
            logging.error('Conditional "%s" has no "params" block, skipping',
                          name)
            continue

        params = cond['params'][0]

        # Check the existence of a "name" parameter for all functions
        # except constants
        if __FUNCTIONS[function] is not __constant:
            if ('name' not in params) or (params['name'] is None):
                logging.error('Conditional "%s" is missing a required '
                              'parameter "name"', name)
                continue

        try:
            results[name] = __FUNCTIONS[function](name, params)
        except Exception as exception:
            # Don't let a single conditional failure destroy
            # everything in this file
            logging.error(str(exception))

    for k, v in results.items():
        logging.debug('Conditional: Name="%s", OK=%r, Result=%r',
                      k, v[0], v[1])

    return results


def is_hidden(conditions, cond_string, name):
    """Returns true if the conditionals say the item should not be
    visible."""

    if is_empty(cond_string):
        logging.warning('Empty conditional in "%s", assuming it\'s visible',
                        name)
        return False

    for cond in cond_string.strip().split(', '):
        original = cond
        wanted = True

        if not is_empty(cond) and cond[0] == '!':
            # negate the condition
            cond = cond[1:]
            wanted = False

        if cond not in conditions:
            logging.error('Undefined condition "%s" in "%s"', cond, name)
            continue

        state = conditions[cond][1]

        if not conditions[cond][0]:
            logging.warning('Conditional "%s" is in indeterminate state, '
                            'assuming it\'s True', name)
            state = True

        if state != wanted:
            logging.info('"%s" is hidden by conditional "%s"',
                         name, original)
            return True

    return False
