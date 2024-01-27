"""XRandr adapter"""

# Standard library imports
import collections
import enum
import re
import subprocess


__all__ = [
    "CallError",
    "Error",
    "UnexpectedOutputError",
    "get_prop",
    "set_max_bpc",
]


class Error(Exception):
    """Baseclass for all errors raised from this module"""


class CallError(Error):
    """Raised when xrandr call fails"""


class UnexpectedOutputError(Error):
    """Raised when xrandr output is unexpected"""


class _State(str, enum.Enum):
    DONE = "DONE"
    INIT = "INIT"
    NO_OUTPUTS = "NO_OUTPUTS"
    OUTPUT = "OUTPUT"
    OUTPUT_MODE = "OUTPUT_MODE"
    OUTPUT_PROP = "OUTPUT_PROP"

    def __str__(self):
        return self.value

    def __repr__(self):
        return repr(self.value)


class _TokenId(str, enum.Enum):
    CONNECTOR = "CONNECTOR"
    EOF = "EOF"
    MODE = "MODE"
    PROP_VALUE_CONTD = "PROP_VALUE_CONTD"
    PROP_ATTR_RANGE = "PROP_ATTR_RANGE"
    PROP_ATTR_SUPPORTED = "PROP_ATTR_SUPPORTED"
    PROP_HEAD = "PROP_HEAD"
    SCREEN = "SCREEN"

    def __str__(self):
        return self.value

    def __repr__(self):
        return repr(self.value)


_TOKEN_REGEXES = collections.OrderedDict(
    (
        (
            _TokenId.CONNECTOR,
            r"^(?P<name>[^\s]+) (?P<state>connected|disconnected) .*$",
        ),
        (
            _TokenId.EOF,
            r"^$",
        ),
        (
            _TokenId.MODE,
            r"^   (?P<resolution>\d+x\d+) (?P<rates>.*?)\s*$",
        ),
        (
            _TokenId.PROP_ATTR_RANGE,
            r"^\t\trange: \((?P<value_min>\d+), (?P<value_max>\d+)\).*$",
        ),
        (
            _TokenId.PROP_ATTR_SUPPORTED,
            r"^\t\tsupported: (?P<supported_values>.*?)\s*$",
        ),
        (
            _TokenId.PROP_VALUE_CONTD,
            r"^\t\t(?P<value>.*?)\s*$",
        ),
        (
            _TokenId.PROP_HEAD,
            r"^\t(?P<name>[^:]+): (?P<value>.*?)\s*$",
        ),
        (
            _TokenId.SCREEN,
            r"^Screen (?P<number>\d+):.*$",
        ),
    )
)


def _tokenize(line):
    for token_id, token_regex in _TOKEN_REGEXES.items():
        token_match = re.match(token_regex, line)
        if token_match is not None:
            return token_id, token_match.groupdict()
    raise UnexpectedOutputError("invalid output line", line)


class _XRandrPropOutputParser:  # pylint: disable=too-few-public-methods
    def __init__(self):
        self.__transitions = {
            # (Current state, Input token): (Action, Next state)
            (_State.INIT, _TokenId.SCREEN): (None, _State.NO_OUTPUTS),
            (_State.NO_OUTPUTS, _TokenId.CONNECTOR): (
                self.__action_create_output,
                _State.OUTPUT,
            ),
            (_State.OUTPUT, _TokenId.PROP_HEAD): (
                self.__action_create_prop,
                _State.OUTPUT_PROP,
            ),
            (_State.OUTPUT_PROP, _TokenId.PROP_VALUE_CONTD): (
                self.__action_append_prop_value,
                _State.OUTPUT_PROP,
            ),
            (_State.OUTPUT_PROP, _TokenId.PROP_ATTR_RANGE): (
                self.__action_add_prop_attr_range,
                _State.OUTPUT_PROP,
            ),
            (_State.OUTPUT_PROP, _TokenId.PROP_ATTR_SUPPORTED): (
                self.__action_add_prop_attr_supported,
                _State.OUTPUT_PROP,
            ),
            (_State.OUTPUT_PROP, _TokenId.PROP_HEAD): (
                self.__action_create_prop,
                _State.OUTPUT_PROP,
            ),
            (_State.OUTPUT_PROP, _TokenId.CONNECTOR): (
                self.__action_create_output,
                _State.OUTPUT,
            ),
            (_State.OUTPUT_PROP, _TokenId.MODE): (None, _State.OUTPUT_MODE),
            (_State.OUTPUT_PROP, _TokenId.EOF): (None, _State.DONE),
            (_State.OUTPUT_MODE, _TokenId.MODE): (None, _State.OUTPUT_MODE),
            (_State.OUTPUT_MODE, _TokenId.CONNECTOR): (
                self.__action_create_output,
                _State.OUTPUT,
            ),
            (_State.OUTPUT_MODE, _TokenId.EOF): (None, _State.DONE),
        }
        self.__current_state = _State.INIT
        self.__displays = {}
        self.__last_output = None
        self.__last_prop = None

    def __action_create_output(
        self,
        token_id,  # pylint: disable=unused-argument
        *,
        name,
        state,
    ):
        if name in self.__displays:
            raise UnexpectedOutputError("display is a duplicate", name)
        self.__displays[name] = self.__last_output = {"name": name, "state": state}

    def __action_create_prop(
        self,
        token_id,  # pylint: disable=unused-argument
        *,
        name,
        value,
    ):
        self.__last_output.setdefault("props", {})[name] = self.__last_prop = {
            "name": name,
            "value": value,
        }

    def __action_append_prop_value(
        self,
        token_id,  # pylint: disable=unused-argument
        *,
        value,
    ):
        self.__last_prop["value"] += value

    def __action_add_prop_attr_range(
        self,
        token_id,  # pylint: disable=unused-argument
        *,
        value_min,
        value_max,
    ):
        # Because this property has range attribute, it must be int.
        self.__last_prop["value"] = int(self.__last_prop["value"], 10)
        self.__last_prop["value_min"] = int(value_min, 10)
        self.__last_prop["value_max"] = int(value_max, 10)

    def __action_add_prop_attr_supported(
        self,
        token_id,  # pylint: disable=unused-argument
        supported_values,
    ):
        self.__last_prop["supported_values"] = [
            v.strip() for v in supported_values.split(",")
        ]

    def __push(self, token_id, token_groupdict):
        action, next_state = self.__transitions[(self.__current_state, token_id)]
        if action is not None:
            action(token_id, **token_groupdict)
        self.__current_state = next_state

    def parse(self, xrandr_prop_output: str) -> dict:
        """Parse xrandr output."""
        for line in xrandr_prop_output.splitlines():
            token_id, token_groupdict = _tokenize(line)
            self.__push(token_id, token_groupdict)
        self.__push(_TokenId.EOF, "")

        return self.__displays


def _call_xrandr(xrandr_args) -> str:
    xrandr_args.insert(0, "xrandr")

    try:
        return subprocess.check_output(xrandr_args).decode("utf-8")
    except subprocess.CalledProcessError as called_process_error:
        raise CallError() from called_process_error


def get_prop() -> dict:
    """Get properties of all display outputs."""
    xrandr_prop_output = _call_xrandr(["--prop"])
    xrandr_prop_output_parser = _XRandrPropOutputParser()

    return xrandr_prop_output_parser.parse(xrandr_prop_output)


def set_max_bpc(output_name: str, max_bpc: int):
    """Set max bpc of a display output"""
    _call_xrandr(
        [
            "--output",
            output_name,
            "--set",
            "max bpc",
            str(max_bpc),
        ]
    )
