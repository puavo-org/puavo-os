# Conditional evaluators

import os
import os.path
import re
import logging

import utils


# ------------------------------------------------------------------------------
# Evaluator classes


class Conditional:
    """Base conditional class."""

    def __init__(self, name):
        # This is the conditional (our) name
        self.name = name

        # This is the name of the thing we're checking for
        self.target_name = None

        # Parameters
        self.params = None


    def parse_params(self, params):
        """Parses the required 'name' parameter from the params block."""

        # By default, the "name" parameter is the only required parameter
        if ('name' not in params) or utils.is_empty(params['name']):
            logging.error('Conditional "%s" is missing a required '
                          'parameter "name" in the params block', self.name)
            return False

        # Ensure the name is a string
        if not isinstance(params['name'], str):
            logging.error('Conditional "%s" has an invalid name "%s" in '
                          'the params block ', self.name, params['name'])
            return False

        self.target_name = params['name']

        self.params = params

        return True


    def evaluate(self):
        """Evaluates the conditional."""

        # Nothing happens by default
        return False


class EnvVar(Conditional):
    """Checks environment variables."""

    def __init__(self, name):
        super().__init__(name)
        self.present = True     # assume envvars are present by default
        self.value = None


    def parse_params(self, params):
        if not super().parse_params(params):
            return False

        if 'present' in self.params:
            self.present = bool(params.get('present', True))

        if 'value' in self.params:
            self.value = self.params['value']

            # Must allow empty values here!
            if not isinstance(self.value, str):
                logging.error('Conditional "%s" has invalid "value" '
                              'parameter', self.name)
                return False

        return True


    def evaluate(self):
        # Is the variable present?
        present = True if self.target_name in os.environ else False

        if self.present != present:
            return False

        if not present:
            # No value checks for variables that shouldn't exist
            return True

        if self.value is None:
            # No value specified, so the value is present, but we don't
            # care about its value
            return True

        # Is the value correct?
        value = os.environ[self.target_name]

        if re.search(self.value, value) is None:
            return False

        return True

# Inherit from EnvVar so we get its parse_params() method. These two
# have the same parameters.
class PuavoConf(EnvVar):
    """Checks puavo-conf variables."""

    def __init__(self, name):
        super().__init__(name)
        self.present = True     # assume puavo-conf variables are present by default
        self.value = None


    def evaluate(self):
        import subprocess

        try:
            proc = subprocess.Popen(['puavo-conf', self.target_name],
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE)
            proc.wait()

            if proc.returncode == 1:
                present = False
                value = None
            else:
                present = True
                value = proc.stdout.read().decode('utf-8').strip()
        except Exception as exception:
            logging.error('PuavoConf::evaluate(): puavo-conf failed:')
            logging.error(str(exception))
            return False

        # Is the variable present?
        if self.present != present:
            return False

        if not present:
            # No value checks for variables that shouldn't exist
            return True

        if self.value is None:
            # No value specified, so the value is present, but we don't
            # care about its value
            return True

        # Is the value correct?
        if re.search(self.value, value) is None:
            return False

        return True


class Const(Conditional):
    """A constant. Always returns true/false. Used primarily during development
    and debugging. Defaults to True if no value has been specified."""

    def __init__(self, name):
        super().__init__(name)
        self.expected = False


    def parse_params(self, params):
        self.expected = bool(params.get('value', True))
        return True


    def evaluate(self):
        return self.expected


# List of known conditions and their evaluator classes
__FUNCTIONS = {
    'env_var': EnvVar,
    'puavo_conf': PuavoConf,
    'constant': Const,
}


# ------------------------------------------------------------------------------


def evaluate_file(file_name):
    """Evaluates the conditionals listed in a file and returns their
    results in a dict."""

    logging.info('Loading a conditionals file "%s"', file_name)

    results = {}

    if not os.path.isfile(file_name):
        logging.error('File "%s" does not exist', file_name)
        return results

    try:
        from yaml import safe_load as yaml_safe_load
        data = yaml_safe_load(open(file_name, 'r', encoding='utf-8').read())
    except Exception as exception:
        logging.error(str(exception))
        return results

    for cond in (data or []):
        try:
            # Check the conditional definition
            if not isinstance(cond, dict):
                logging.error('Skipping an invalid conditional definition "%s"',
                              str(cond))
                continue

            # Check the conditional name
            if 'name' not in cond:
                logging.error('Ignoring a conditional without a name')
                continue

            name = cond['name']

            if (not isinstance(name, str)) or utils.is_empty(name):
                logging.error('Ignoring a conditional with empty/invalid name '
                              '("%s" is not valid)', name)
                continue

            if name in results:
                logging.error('Duplicate conditional "%s", skipping', name)
                continue

            # Check the function name
            if 'function' not in cond:
                logging.error('Conditional "%s" has no function defined, skipping',
                              name)
                continue

            function = cond['function']

            if (not isinstance(function, str)) or utils.is_empty(function):
                logging.error('Ignoring a conditional with empty/invalid function '
                              '("%s" is not valid)', function)
                continue

            if function not in __FUNCTIONS:
                logging.error('Conditional "%s" has an unknown function "%s", '
                              'skipping', name, function)
                continue

            # Check the params block
            if ('params' not in cond) or (cond['params'] is None):
                logging.error('Conditional "%s" has no "params" block, skipping',
                              name)
                continue

            params = cond['params'][0]

            if (not isinstance(params, dict)) or utils.is_empty(params):
                logging.error('Conditional "%s" invalid/empty params block, '
                              'skipping', name)
                continue

            # Evaluate and store
            cond = __FUNCTIONS[function](name)

            if not cond.parse_params(params):
                continue

            results[name] = cond.evaluate()
        except Exception as exception:
            # Don't let a single conditional failure destroy
            # everything in this file
            logging.error(str(exception))
            return results

    for key, value in results.items():
        logging.debug('Conditional: Name="%s", Result=%r', key, value)

    return results


def is_hidden(conditions, cond_string, name, item_type=None):
    """Returns true if the conditionals say the item should not be
    visible."""

    if not item_type:
        item_type = ''
    else:
        # add whitespace at the end so messages look nice
        item_type = item_type + ' '

    if utils.is_empty(cond_string):
        logging.warning('Empty conditional in %s"%s", assuming it\'s visible',
                        item_type, name)
        return False

    # Multiple conditional names can be specified; they all must evaluate
    # to True for the whole string to evaluate to True
    for cond in cond_string.strip().split(', '):
        original = cond
        wanted = True

        if not utils.is_empty(cond) and cond[0] == '!':
            # negate the condition
            cond = cond[1:]
            wanted = False

        if cond not in conditions:
            logging.error('Undefined condition "%s" in %s"%s"',
                          cond, item_type, name)
            continue

        if conditions[cond] != wanted:
            logging.info('%s"%s" is hidden by conditional "%s"',
                         item_type, name, original)
            return True

    return False
