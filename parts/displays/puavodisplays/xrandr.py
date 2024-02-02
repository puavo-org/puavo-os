"""XRandr adapter"""

# Standard library imports
import collections
import enum
import logging
import re
import subprocess
import typing

__all__ = [
    "CallError",
    "Error",
    "UnexpectedOutputError",
    "get_prop",
    "set_max_bpc",
    "set_max_bpc_of_all_display_outputs",
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

    def __str__(self) -> str:
        return self.value

    def __repr__(self) -> str:
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

    def __str__(self) -> str:
        return self.value

    def __repr__(self) -> str:
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


def _tokenize(line: str) -> typing.Tuple[_TokenId, typing.Dict[str, str]]:
    for token_id, token_regex in _TOKEN_REGEXES.items():
        token_match = re.match(token_regex, line)
        if token_match is not None:
            return token_id, token_match.groupdict()
    raise UnexpectedOutputError("invalid output line", line)


class _XRandrPropOutputParser:  # pylint: disable=too-few-public-methods
    def __init__(self) -> None:
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
        self.__displays: typing.Dict[str, typing.Dict[str, typing.Any]] = {}
        self.__last_output: typing.Dict[str, typing.Any] = {}
        self.__last_prop: typing.Dict[str, typing.Any] = {}

    def __action_create_output(
        self,
        token_id: _TokenId,  # pylint: disable=unused-argument
        *,
        name: str,
        state: str,
    ) -> None:
        if name in self.__displays:
            raise UnexpectedOutputError("display is a duplicate", name)
        self.__displays[name] = self.__last_output = {"name": name, "state": state}

    def __action_create_prop(
        self,
        token_id: _TokenId,  # pylint: disable=unused-argument
        *,
        name: str,
        value: str,
    ) -> None:
        self.__last_output.setdefault("props", {})[name] = self.__last_prop = {
            "name": name,
            "value": value,
        }

    def __action_append_prop_value(
        self,
        token_id: _TokenId,  # pylint: disable=unused-argument
        *,
        value: str,
    ) -> None:
        self.__last_prop["value"] += value

    def __action_add_prop_attr_range(
        self,
        token_id: _TokenId,  # pylint: disable=unused-argument
        *,
        value_min: str,
        value_max: str,
    ) -> None:
        # Because this property has range attribute, it must be int.
        self.__last_prop["value"] = int(self.__last_prop["value"], 10)
        self.__last_prop["value_min"] = int(value_min, 10)
        self.__last_prop["value_max"] = int(value_max, 10)

    def __action_add_prop_attr_supported(
        self,
        token_id: _TokenId,  # pylint: disable=unused-argument
        supported_values: str,
    ) -> None:
        self.__last_prop["supported_values"] = [
            v.strip() for v in supported_values.split(",")
        ]

    def __push(
        self, token_id: _TokenId, token_groupdict: typing.Dict[str, str]
    ) -> None:
        action, next_state = self.__transitions[(self.__current_state, token_id)]
        if action is not None:
            action(token_id, **token_groupdict)
        self.__current_state = next_state

    def parse(
        self, xrandr_prop_output: str
    ) -> typing.Dict[str, typing.Dict[str, typing.Any]]:
        """Parse xrandr output."""
        for line in xrandr_prop_output.splitlines():
            token_id, token_groupdict = _tokenize(line)
            self.__push(token_id, token_groupdict)
        self.__push(_TokenId.EOF, {})

        return self.__displays


def _call_xrandr(xrandr_args: typing.List[str]) -> str:
    xrandr_args.insert(0, "xrandr")

    try:
        return subprocess.check_output(xrandr_args).decode("utf-8")
    except subprocess.CalledProcessError as called_process_error:
        raise CallError() from called_process_error


def get_prop() -> typing.Dict[str, typing.Dict[str, typing.Any]]:
    """Get properties of all display outputs."""
    xrandr_prop_output = _call_xrandr(["--prop"])
    xrandr_prop_output_parser = _XRandrPropOutputParser()

    return xrandr_prop_output_parser.parse(xrandr_prop_output)


def set_max_bpc(max_bpc_per_output: typing.Dict[str, int]) -> None:
    """Set max bpc of display outputs."""
    xrandr_args = []

    for output_name, max_bpc in max_bpc_per_output.items():
        xrandr_args.append("--output")
        xrandr_args.append(output_name)
        xrandr_args.append("--set")
        xrandr_args.append("max bpc")
        xrandr_args.append(str(max_bpc))

    _call_xrandr(xrandr_args)


def set_max_bpc_of_all_display_outputs(
    desired_max_bpc: int, *, logger: typing.Optional[logging.Logger] = None
) -> None:
    """Set max bpc of all display outputs.

    If logger is defined, it is used for logging the progress.
    """

    max_bpc_per_output = {}

    for output_name, output in get_prop().items():
        if "max bpc" in output["props"]:
            if logger:
                logger.info("desired max bpc of %r is %d", output_name, desired_max_bpc)

            max_bpc_prop = output["props"]["max bpc"]
            current_value = max_bpc_prop["value"]
            value_min = max_bpc_prop["value_min"]
            value_max = max_bpc_prop["value_max"]

            new_value = min(max(value_min, desired_max_bpc), value_max)
            if new_value != desired_max_bpc:
                if logger:
                    logger.info(
                        "adjusted desired max bpc of %r from %d to %d to "
                        "match the supported range (%d, %d)",
                        output_name,
                        desired_max_bpc,
                        new_value,
                        value_min,
                        value_max,
                    )
            if logger:
                logger.info(
                    "setting max bpc of %r from %d to %d",
                    output_name,
                    current_value,
                    new_value,
                )
            max_bpc_per_output[output_name] = new_value

    set_max_bpc(max_bpc_per_output)
