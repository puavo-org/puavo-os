# Conditional evaluators

import os
import subprocess
import logging

import utils


def __validate_common_params(name, data):
    if 'params' not in data:
        logging.error('Conditional "%s" has no params block', name)
        return None

    params = data['params']

    if not isinstance(params, dict) or len(params) == 0:
        logging.error('Conditional "%s" has invalid or empty params block', name)
        return None

    if 'name' not in params or not isinstance(params['name'], str) or utils.is_empty(params['name']):
        logging.error('Conditional "%s" has a missing, invalid or empty "name" parameter', name)
        return None

    return params


def __do_env_var(name, data):
    params = __validate_common_params(name, data)

    if params is None:
        return None

    # Get the environment variable value
    target_value = os.getenv(params['name'], None)

    # Then figure out what to check it against
    check_name = None
    regexp = False

    if 'value' in params:
        check_name = 'value'
    elif 'regexp_value' in params:
        check_name = 'regexp_value'
        regexp = True

    if check_name is None:
        # No value has been specified, the environment variable
        # simply needs to exist
        if target_value is None:
            return False
        else:
            return True

    # But if there is a value, then it must be a string. It can be empty.
    if not isinstance(params[check_name], str):
        logging.error('Conditional "%s" has an invalid "%s" parameter', name, check_name)
        logging.error('(Environment conditional values must be strings if present)')
        return None

    if target_value is None:
        # A value is needed, but the environment variable does not exist
        return False

    if regexp:
        if re.search(params['regexp_value'], target_value) is None:
            return False
        else:
            return True
    else:
        return params['value'] == target_value


def __do_puavoconf(name, data):
    params = __validate_common_params(name, data)

    if params is None:
        return None

    # Retrieve value
    try:
        proc = subprocess.Popen(
            ['puavo-conf', params['name']],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

        proc.wait()

        if proc.returncode == 1:
            present = False
            target_value = None
        else:
            present = True
            target_value = proc.stdout.read().decode('utf-8').strip()
    except Exception as exception:
        logging.error("Can't determine the value of conditional \"%s\", a call to puavo-conf failed:",
                      name)
        logging.error(exception, exc_info=True)
        return None

    # Then figure out what to check it against
    check_name = None
    regexp = False

    if 'value' in params:
        check_name = 'value'
    elif 'regexp_value' in params:
        check_name = 'regexp_value'
        regexp = True

    if check_name is None:
        # No value has been specified, the mere presence is enough
        return present

    # Need a value
    if not isinstance(params[check_name], str):
        logging.error('Conditional "%s" has an invalid "%s" parameter', name, check_name)
        logging.error('(puavo-conf conditional values must be strings if present)')
        return None

    if not present:
        # A value is needed, but the puavo-conf variable does not exist
        return False

    if regexp:
        if re.search(params['regexp_value'], target_value) is None:
            return False
        else:
            return True
    else:
        return params['value'] == target_value


def __do_constant(name, data):
    if 'params' not in data:
        logging.error('Conditional "%s" has no params block', name)
        return None

    params = data['params']

    if not isinstance(params, dict) or len(params) == 0:
        logging.error('Conditional "%s" has invalid or empty params block', name)
        return None

    if 'value' not in params:
        logging.error('Conditional "%s" has no boolean \"value\" defined', name)
        return None

    if isinstance(params['value'], bool):
        return params['value']

    logging.error('Conditional "%s" has no boolean \"value\" defined', name)
    return None


__CONDITIONAL_EVALUATORS = {
    'env_var': __do_env_var,
    'puavo_conf': __do_puavoconf,
    'constant': __do_constant,
}


# ------------------------------------------------------------------------------


# Loads conditionals from a dict. The dict can be loaded from a JSON/YAML
# file, or built by hand.
def load(data):
    if not isinstance(data, dict):
        logging.error('Cannot load conditionals, data is not a dict')
        return {}

    out = {}

    for name, cond in data.items():
        # Check the function name
        if 'function' not in cond:
            logging.error(
                'Conditional "%s" has no function defined, skipping',
                name)
            continue

        function = cond['function']

        if (not isinstance(function, str)) or utils.is_empty(function):
            logging.error(
                'Ignoring a conditional with empty/invalid function '
                '("%s" is not valid)', function)
            continue

        if function not in __CONDITIONAL_EVALUATORS:
            logging.error(
                'Conditional "%s" has an unknown function "%s", skipping',
                name, function)
            continue

        # Store the conditional as-is. We can't really validate it yet.
        out[name] = cond

    return out


# Evaluates the conditionals
def evaluate(conditionals):
    out = {}

    for name, cond in conditionals.items():
        function = cond['function']

        if function in __CONDITIONAL_EVALUATORS:
            try:
                ret = __CONDITIONAL_EVALUATORS[function](name, cond)
            except Exception as exc:
                # don't let one failed conditional to stop everything
                logging.error("Could not evaluate conditional \"%s\":", name)
                logging.error(exc, exc_info=True)
                continue
        else:
            logging.error(
                'Conditional "%s" has an invalid function "%s", assuming it\'s false',
                name, function)
            ret = False

        if ret == None:
            logging.error(
                'Cannot determine the value for conditional \"%s\", assuming it\'s false',
                name)
            ret = False

        logging.debug('Conditional "%s", value "%s"', name, ret)
        out[name] = ret

    return out


# Returns true if the conditionals say the item should not be visible
def is_hidden(conditionals, cond_string, name, item_type):
    if utils.is_empty(cond_string):
        logging.warning(
            'Empty conditional in %s "%s", assuming it\'s visible',
            item_type, name)
        return False

    # Multiple conditional names can be specified; they all must evaluate
    # to True. Equivalent to "foo && bar && baz", with optional negation
    # specified like this: "foo && !bar && baz".
    for cond in cond_string.strip().split(', '):
        original = cond
        wanted = True

        if not utils.is_empty(cond) and cond[0] == '!':
            # negate the state
            cond = cond[1:]
            wanted = False

        if cond not in conditionals:
            logging.error(
                'Undefined conditional "%s" in %s "%s"',
                cond, item_type, name)
            continue

        if conditionals[cond] != wanted:
            logging.debug('Conditional string "%s" hides %s "%s"', cond_string, item_type, name)
            return True

    logging.debug('Conditional string "%s" shows %s "%s"', cond_string, item_type, name)
    return False
