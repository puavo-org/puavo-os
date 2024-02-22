"""Puavo conf adapter"""

# Standard library imports
import subprocess
import typing

__all__ = [
    "Error",
    "ValueConversionError",
    "get",
    "get_as",
]


class Error(Exception):
    """Baseclass for all exceptions raised from this module"""


class ValueConversionError(Error):
    """Raised when configuration value cannot be converted to given type"""


T = typing.TypeVar("T")


def get_as(conf_key: str, type_func: typing.Callable[[str], T]) -> T:
    """Return Puavo conf value as type T

    type_func is function which converts str to T or raises ValueError
    if str cannot be converted.
    """

    value_str = (
        subprocess.check_output(["puavo-conf", conf_key]).decode("utf-8").strip()
    )
    try:
        return type_func(value_str)
    except ValueError as orig_value_error:
        raise ValueConversionError(
            f"invalid {conf_key!r} value {value_str!r}, "
            f"cannot be converted with {type_func.__name__!r}"
        ) from orig_value_error


def get(conf_key: str) -> str:
    """Return Puavo conf value as str"""
    return get_as(conf_key, str)
