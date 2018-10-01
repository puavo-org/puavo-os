# Conditional evaluators

from os.path import exists as path_exists, \
                    isfile as is_file, \
                    getsize as get_size

import os, re, stat

import logger

from utils import is_empty

# ------------------------------------------------------------------------------
# Evaluators

def __file_check(name, params):
    """Checks if a file exists/does not exist. Optional checks include
    size, hash and content checks."""

    # This is the *file* name, not the conditional name
    if 'name' not in params:
        logger.error('Conditional "{0}" is missing a required '
                     'parameter "name"'.format(name))
        return (False, False)

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
                    logger.error('Negative file size specified in '
                                 'conditional "{0}"'.format(name))
                    return (False, False)

                if get_size(params['name']) != size:
                    return (True, False)

            if 'hash' in params:
                # SHA256 hash check
                if len(params['hash']) != 64:
                    logger.error('Invalid hash (wrong size) specified in '
                                 'conditional "{0}"'.format(name))
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

    if 'name' not in params:
        logger.error('Conditional "{0}" is missing a required '
                     'parameter "name"'.format(name))
        return (False, False)

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

    if 'name' not in params:
        logger.error('Conditional "{0}" is missing a required '
                     'parameter "name"'.format(name))
        return (False, False)

    state = True if params['name'] in os.environ else False
    present = params.get('present', True)

    if present == state:
        if present and 'value' in params:
            # content check
            wanted = params['value']
            got = os.environ[params['name']]

            logger.debug('env_var "{0}": wanted="{1}" got="{2}" result={3}'.
                         format(params['name'], wanted, got, wanted == got))

            if re.search(wanted, got) is None:
                return (True, False)

        return (True, True)

    return (True, False)


def __puavo_conf(name, params):
    """Puavo-conf variable presence (and optionally content) check."""

    if 'name' not in params:
        logger.error('Conditional "{0}" is missing a required '
                     'parameter "name"'.format(name))
        return (False, False)

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

            logger.debug('puavo_conf "{0}": wanted="{1}" got="{2}" result={3}'.
                         format(params['name'], wanted, got, wanted == got))

            if re.search(wanted, got) is None:
                return (True, False)

        return (True, True)

    return (True, False)


def __constant(name, params):
    """Returns a constant true/false value. Defaults to true if no value
    has been specified. Used mostly in debugging/development."""

    return (True, params.get('value', True))


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

    logger.info('Loading a conditionals file "{0}"'.format(file_name))

    results = {}

    if not is_file(file_name):
        logger.error('File "{0}" does not exist'.format(file_name))
        return results

    try:
        from yaml import safe_load as yaml_safe_load
        data = yaml_safe_load(open(file_name, 'r', encoding='utf-8').read())
    except Exception as e:
        logger.error(e)
        return results

    for cond in (data or []):
        if 'name' not in cond:
            logger.error('Ignoring a conditional without a name '
                         '(missing the "name" key)')
            continue

        name = cond['name']

        if name in results:
            logger.error('Duplicate conditional "{0}", skipping'.
                         format(name))
            continue

        if 'function' not in cond:
            logger.error('Conditional "{0}" has no function defined, skipping'.
                         format(name))
            continue

        function = cond['function']

        if function not in __FUNCTIONS:
            logger.error('Conditional "{0}" has an unknown function "{1}", '
                         'skipping'.format(name, function))
            continue

        if ('params' not in cond) or (cond['params'] is None):
            logger.error('Conditional "{0}" has no "params" block, skipping'.
                         format(name))
            continue

        try:
            results[name] = __FUNCTIONS[function](name, cond['params'][0])
        except Exception as e:
            # Don't let a single conditional failure destroy
            # everything in this file
            logger.error(e)

    for k, v in results.items():
        logger.debug('Conditional: Name="{0}", OK={1}, Result={2}'.
                     format(k, v[0], v[1]))

    return results


def is_hidden(conditions, cond_string, name):
    """Returns true if the conditionals say the item should not be
    visible."""

    if is_empty(cond_string):
        logger.warn('Empty conditional in "{0}", assuming it\'s visible'.
                    format(name))
        return False

    for cond in cond_string.strip().split(', '):
        original = cond
        wanted = True

        if not is_empty(cond) and cond[0] == '!':
            # negate the condition
            cond = cond[1:]
            wanted = False

        if cond not in conditions:
            logger.error('Undefined condition "{0}" in "{1}"'.
                         format(cond, name))
            continue

        state = conditions[cond][1]

        if not conditions[cond][0]:
            logger.warn('Conditional "{0}" is in indeterminate state, '
                        'assuming it\'s True'.format(name))
            state = True

        if state != wanted:
            logger.info('"{0}" is hidden by conditional "{1}"'.
                        format(name, original))
            return True

    return False
