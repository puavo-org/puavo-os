"""
Access Puavo configuration
"""

# Standard library imports
import ipaddress
import subprocess
import typing

# Third-party imports
import puavo_ers.net

_PuavoConfValueT = typing.TypeVar("_PuavoConfValueT")

__all__ = [
    "is_ers_mode_abitti2server",
    "get_ers_abitti2server_interface",
    "get_ers_abitti2server_network",
    "get_ers_abitti2server_number",
]


class ValidationError(Exception):
    def __init__(self, message, value):
        self.puavoconf_key = None
        self.value = value
        self.message = message

    def __str__(self) -> str:
        if self.puavoconf_key:
            return f"'{self.puavoconf_key}' has invalid value '{self.value}': {self.message}"

        return f"invalid value '{self.value}': {self.message}"


def _puavoconf_get(
    puavoconf_key: str, validator: typing.Callable[[str], _PuavoConfValueT]
) -> _PuavoConfValueT:
    puavo_conf_string_value = (
        subprocess.check_output(["puavo-conf", puavoconf_key]).rstrip().decode("utf-8")
    )

    try:
        return validator(puavo_conf_string_value)
    except ValidationError as validation_error:
        validation_error.puavoconf_key = puavoconf_key
        raise validation_error


def validate_abitti2server_mode(s: str) -> str:
    if s == "abitti2server":
        return s

    raise ValidationError("invalid mode", s)


def validate_abitti2server_interface(
    maybe_invalid_abitti2server_interface: str,
) -> str:
    if not maybe_invalid_abitti2server_interface:
        return ""

    if maybe_invalid_abitti2server_interface not in puavo_ers.net.interfaces():
        raise ValidationError(
            "interface does not exist", maybe_invalid_abitti2server_interface
        )

    return str(maybe_invalid_abitti2server_interface)


def validate_abitti2server_network(
    maybe_invalid_abitti2server_network_address: str,
) -> str:
    if not maybe_invalid_abitti2server_network_address:
        return ""

    network = ipaddress.IPv4Network(maybe_invalid_abitti2server_network_address)

    if not network.is_private:
        raise ValidationError(
            "network is not private", maybe_invalid_abitti2server_network_address
        )

    if network.prefixlen != 16:
        raise ValidationError(
            "network has invalid size, CIDR prefix length must be 16",
            maybe_invalid_abitti2server_network_address,
        )

    return str(network)


def validate_abitti2server_number(
    maybe_invalid_abitti2server_number: str,
) -> int:
    if not maybe_invalid_abitti2server_number:
        raise ValidationError("number is invalid", maybe_invalid_abitti2server_number)

    try:
        number = int(maybe_invalid_abitti2server_number)
    except ValueError as value_error:
        raise ValidationError(
            "number is invalid", maybe_invalid_abitti2server_number
        ) from value_error

    if 1 > number or number > 254:
        raise ValidationError(
            "number is not betwen 1 and 254", maybe_invalid_abitti2server_number
        )

    return number


def is_ers_mode_abitti2server() -> bool:
    try:
        _puavoconf_get("puavo.ers.mode", validate_abitti2server_mode)
    except ValidationError:
        return False
    return True


def get_ers_abitti2server_interface() -> str:
    return _puavoconf_get(
        "puavo.ers.abitti2server.interface", validate_abitti2server_interface
    )


def get_ers_abitti2server_network() -> str:
    return _puavoconf_get(
        "puavo.ers.abitti2server.network", validate_abitti2server_network
    )


def get_ers_abitti2server_number() -> int:
    return _puavoconf_get(
        "puavo.ers.abitti2server.number", validate_abitti2server_number
    )
