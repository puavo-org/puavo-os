# Conditional evaluators

# TODO:
#  - merge file_check and dir_check into path_check that can check types,
#    sizes, hashes (multiple algorithms?), contents, owner/group, mode, etc.
#  - regexp file/envvar/puavoconf content checks?
#  - support checking multiple files/dirs/envvars/puavoconf names and values
#    in one call?

from os.path import exists as path_exists, \
                    isfile as is_file, \
                    getsize as get_size

import os, stat

from logger import debug as log_debug, \
                   error as log_error, \
                   warn as log_warn, \
                   info as log_info

from utils import is_empty


def __file_check(name, params):
    """Checks if a file exists/does not exist. Optional checks include
    size, hash and content checks."""

    # This is the *file* name, not the conditional name
    if 'name' not in params:
        log_error('Conditional "{0}" is missing a required '
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
                    log_error('Negative file size specified in '
                              'conditional "{0}"'.format(name))
                    return (False, False)

                if get_size(params['name']) != size:
                    return (True, False)

            if 'hash' in params:
                # SHA256 hash check
                if len(params['hash']) != 64:
                    log_error('Invalid hash (wrong size) specified in '
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
        log_error('Conditional "{0}" is missing a required '
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
        log_error('Conditional "{0}" is missing a required '
                  'parameter "name"'.format(name))
        return (False, False)

    state = True if params['name'] in os.environ else False
    present = params.get('present', True)

    if present == state:
        if present and 'value' in params:
            # content check
            if os.environ[params['name']] != params['value']:
                return (True, False)

        return (True, True)

    return (True, False)


def __puavo_conf(name, params):
    """Puavo-conf variable check."""

    if 'name' not in params:
        log_error('Conditional "{0}" is missing a required '
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
            if params['value'] != \
                   proc.stdout.read().decode('utf-8').strip():
                return (True, False)

        return (True, True)

    return (True, False)


def __constant(name, params):
    """Returns a constant true/false value. Defaults to true if no value
    has been specified. Used mostly in debugging/development."""

    return (True, params.get('value', True))


# List of known conditions and their evaluator methods
__METHODS = {
    'file_check': __file_check,
    'dir_check': __dir_check,
    'env_var': __env_var,
    'puavo_conf': __puavo_conf,
    'constant': __constant,
}


def evaluate_file(file_name):
    """Evaluates the conditionals listed in a file and returns their
    results in a dict."""

    log_info('Loading a conditionals file "{0}"'.format(file_name))

    results = {}

    if not is_file(file_name):
        log_error('File "{0}" does not exist'.format(file_name))
        return results

    try:
        from yaml import safe_load as yaml_safe_load
        data = yaml_safe_load(open(file_name, 'r', encoding='utf-8').read())
    except Exception as e:
        log_error(e)
        return results

    for cond in (data or []):
        if 'name' not in cond:
            log_error('Ignoring a conditional without a name (missing "name" key)')
            continue

        name = cond['name']

        if name in results:
            log_error('Duplicate conditional "{0}", skipping'.
                      format(name))
            continue

        if 'method' not in cond:
            log_error('Conditional "{0}" has no method defined, skipping'.
                      format(name))
            continue

        method = cond['method']

        if method not in __METHODS:
            log_error('Conditional "{0}" has an unknown method "{1}", '
                      'skipping'.format(name, method))
            continue

        if ('params' not in cond) or (cond['params'] is None):
            log_error('Conditional "{0}" has no "params" block, skipping'.
                      format(name))
            continue

        try:
            results[name] = __METHODS[method](name, cond['params'][0])
        except Exception as e:
            # Don't let a single conditional failure remove
            # everything in this file
            log_error(e)

    for k, v in results.items():
        log_debug('Conditional: name="{0}", OK={1}, result={2}'.format(k, v[0], v[1]))

    return results


def is_hidden(conditions, cond_string, name):
    """Returns true if the conditionals say the item should not be
    visible."""

    if is_empty(cond_string):
        log_warn('Empty conditional in "{0}", assuming it\'s visible'.
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
            log_error('Undefined condition "{0}" in "{1}"'.
                      format(cond, name))
            continue

        state = conditions[cond][1]

        if not conditions[cond][0]:
            log_warn('Conditional "{0}" is in indeterminate state, '
                     'assuming it\'s True'.format(name))
            state = True

        if state != wanted:
            log_info('"{0}" is hidden by conditional "{1}"'.
                     format(name, original))
            return True

    return False
