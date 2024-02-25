"""Mutter adapter"""

# Standard library imports
import collections
import dataclasses
import enum
import typing

# Third-party imports
import dbus  # type: ignore[import]
import dbus.mainloop.glib  # type: ignore[import]

import pydantic
import pydantic.main
import pydantic.types


__all__ = [
    "LogicalMonitorConfiguration",
    "LogicalMonitorState",
    "Method",
    "MonitorConfiguration",
    "MonitorIdentity",
    "MonitorMode",
    "MonitorState",
    "MonitorsConfig",
    "Mutter",
    "State",
    "Transform",
]


class Method(enum.IntEnum):
    """Mutter configuration application method"""

    VERIFY = 0
    TEMPORARY = 1
    PERSISTENT = 2


class Transform(enum.IntEnum):
    """Mutter display transformation"""

    NORMAL = 0
    ROTATED_90 = 1
    ROTATED_180 = 2
    ROTATED_270 = 3
    FLIPPED = 4
    FLIPPED_90 = 5
    FLIPPED_180 = 6
    FLIPPED_270 = 7


@dataclasses.dataclass
class MonitorMode:
    """Mutter monitor monitor mode"""

    id: pydantic.types.StrictStr  # pylint: disable=invalid-name
    width: pydantic.types.PositiveInt
    height: pydantic.types.PositiveInt
    refresh_rate: pydantic.types.PositiveFloat
    preferred_scale: pydantic.types.PositiveFloat
    supported_scales: typing.List[pydantic.types.PositiveFloat]
    properties: typing.Dict[pydantic.types.StrictStr, typing.Any]


@dataclasses.dataclass
class MonitorIdentity:
    """Mutter monitor identity"""

    connector: pydantic.types.StrictStr
    vendor: pydantic.types.StrictStr
    product: pydantic.types.StrictStr
    serial: pydantic.types.StrictStr


@dataclasses.dataclass(kw_only=True)
class MonitorState:
    """Mutter (physical) monitor state"""

    identity: MonitorIdentity
    modes: typing.List[MonitorMode]
    properties: typing.Dict[pydantic.types.StrictStr, typing.Any]


@dataclasses.dataclass(kw_only=True)
class _LogicalMonitor:
    x: pydantic.types.NonNegativeInt  # pylint: disable=invalid-name
    y: pydantic.types.NonNegativeInt  # pylint: disable=invalid-name
    scale: pydantic.types.PositiveFloat
    transform: Transform
    primary: bool


@dataclasses.dataclass(kw_only=True)
class LogicalMonitorState(_LogicalMonitor):
    """Mutter logical monitor state"""

    monitors: typing.List[MonitorIdentity]
    properties: typing.Dict[pydantic.types.StrictStr, typing.Any]


@pydantic.validate_arguments
@dataclasses.dataclass(kw_only=True)
class State:
    """State of display setup as seen by Mutter"""

    serial: pydantic.types.NonNegativeInt
    monitors: typing.List[MonitorState]
    logical_monitors: typing.List[LogicalMonitorState]
    properties: typing.Dict[pydantic.types.StrictStr, typing.Any]


@dataclasses.dataclass(kw_only=True)
class MonitorConfiguration:
    """Mutter (physical) monitor configuration"""

    mode_id: pydantic.types.StrictStr
    properties: typing.Dict[str, typing.Any] = dataclasses.field(default_factory=dict)


@dataclasses.dataclass(kw_only=True)
class LogicalMonitorConfiguration(_LogicalMonitor):
    """Mutter logical monitor configuration"""

    monitors: typing.OrderedDict[str, MonitorConfiguration] = dataclasses.field(
        default_factory=collections.OrderedDict
    )


@dataclasses.dataclass(kw_only=True)
class MonitorsConfig:
    """Class representing the configuration passed to org.gnome.Mutter.ApplyMonitorsConfig()"""

    serial: pydantic.types.NonNegativeInt
    logical_monitors: typing.List[LogicalMonitorConfiguration] = dataclasses.field(
        default_factory=list
    )
    properties: typing.Dict[str, typing.Any] = dataclasses.field(default_factory=dict)


def _state_to_monitors_config(state: State) -> MonitorsConfig:
    current_monitor_configurations = {}

    monitors_config = MonitorsConfig(serial=state.serial)

    for monitor in state.monitors:
        for mode in monitor.modes:
            if mode.properties.get("is-current", False):
                current_monitor_configurations[
                    monitor.identity.connector
                ] = MonitorConfiguration(mode_id=mode.id)

    for logical_monitor_state in state.logical_monitors:
        logical_monitor_dict = dataclasses.asdict(logical_monitor_state)

        # org.gnome.Mutter.ApplyMonitorsConfig does not support logical monitor properties.
        logical_monitor_dict.pop("properties")

        monitor_identities = logical_monitor_dict.pop("monitors")

        logical_monitor_configuration = LogicalMonitorConfiguration(
            **logical_monitor_dict
        )

        for monitor_identity in monitor_identities:
            connector = monitor_identity["connector"]
            logical_monitor_configuration.monitors[
                connector
            ] = current_monitor_configurations[connector]

        monitors_config.logical_monitors.append(logical_monitor_configuration)

    return monitors_config


class Mutter:
    """Mutter DBus interface abstraction."""

    def __init__(self) -> None:
        self.__dbus_bus = dbus.SessionBus()
        self.__dbus_object = self.__dbus_bus.get_object(
            "org.gnome.Mutter.DisplayConfig", "/org/gnome/Mutter/DisplayConfig"
        )
        self.__dbus_interface = dbus.Interface(
            self.__dbus_object, dbus_interface="org.gnome.Mutter.DisplayConfig"
        )

    def get_monitors_config(self) -> MonitorsConfig:
        """Return the current state of the display setup as a monitor configuration.

        The returned object can be fed back to Mutter via apply_monitors_config().

        Calls org.gnome.Mutter.GetCurrentState()
        """

        state = self.get_current_state()
        return _state_to_monitors_config(state)

    def get_current_state(self) -> State:
        """Return the current state of the display setup.

        Calls org.gnome.Mutter.GetCurrentState()
        """

        (
            serial,
            monitor_structs,
            logical_monitor_structs,
            properties,
        ) = self.__dbus_interface.GetCurrentState()

        monitors = []
        for identity, modes, properties in monitor_structs:
            monitors.append(
                MonitorState(
                    identity=MonitorIdentity(*identity),
                    modes=[MonitorMode(*mode) for mode in modes],
                    properties=properties,
                )
            )

        logical_monitors = []
        for (
            x,  # pylint: disable=invalid-name
            y,  # pylint: disable=invalid-name
            scale,
            transform,
            primary,
            identities,
            properties,
        ) in logical_monitor_structs:
            logical_monitors.append(
                LogicalMonitorState(
                    x=x,
                    y=y,
                    scale=scale,
                    transform=Transform(transform),
                    primary=primary,
                    monitors=[MonitorIdentity(*i) for i in identities],
                    properties=properties,
                )
            )

        return State(
            serial=serial,
            monitors=monitors,
            logical_monitors=logical_monitors,
            properties=properties,
        )

    @pydantic.validate_arguments
    def apply_monitors_config(
        self,
        monitors_config: MonitorsConfig,
        *,
        method: Method,
    ) -> None:
        """Apply monitor configuration.

        Calls org.gnome.Mutter.ApplyMonitorsConfig()
        """

        logical_monitors = [
            list(dataclasses.astuple(m)) for m in monitors_config.logical_monitors
        ]

        # org.gnome.Mutter.ApplyMonitorsConfig eats monitor
        # configurations as tuples, so transform OrderDict entries to
        # tuples.
        for logical_monitor in logical_monitors:
            logical_monitor[5] = [
                (connector, mode_id, properties)
                for connector, (
                    mode_id,
                    properties,
                ) in logical_monitor[5].items()
            ]

        self.__dbus_interface.ApplyMonitorsConfig(
            monitors_config.serial,
            method,
            logical_monitors,
            monitors_config.properties,
        )


def reset_scale() -> None:
    """Reset scale of all logical displays"""
    mutter = Mutter()

    monitors_config = mutter.get_monitors_config()
    for logical_monitor in monitors_config.logical_monitors:
        logical_monitor.scale = 1

    mutter.apply_monitors_config(
        monitors_config,
        method=Method.TEMPORARY,
    )
