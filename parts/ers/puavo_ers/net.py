"""
Manage networking
"""

# Standard library imports
import ipaddress
import logging
import os.path
import subprocess
import time
import typing

_LOGGER = logging.getLogger(os.path.basename(__file__))

# Third-party imports
import netifaces

__all__ = [
    "interfaces",
    "interface_addresses",
    "Net",
]


def wait_interface(interface_name: str, *, timeout: float) -> bool:
    start_time = time.time()
    while time.time() - start_time < timeout:
        addresses = netifaces.ifaddresses(interface_name)
        if netifaces.AF_INET in addresses:
            with open(
                f"/sys/class/net/{interface_name}/operstate", encoding="ascii"
            ) as operstate_file:
                if operstate_file.read().strip().upper() == "UP":
                    return True

        time.sleep(0.5)

    return False


def interfaces() -> typing.List[str]:
    return netifaces.interfaces()


def interface_addresses(interface):
    return {
        netifaces.address_families[k]: v
        for k, v in netifaces.ifaddresses(interface).items()
    }


class Net:
    def __init__(self, interface_name: str, network: str, dhcp_subnet_number: int):
        if interface_name not in interfaces():
            raise ValueError("invalid interface_name", interface_name)
        self.__interface_name = interface_name
        self.__network = ipaddress.IPv4Network(network)
        self.__dhcp_subnet = list(self.__network.subnets(8))[dhcp_subnet_number]
        self.__was_managed = False

    @property
    def interface_name(self) -> str:
        return self.__interface_name

    @property
    def host_address(self) -> ipaddress.IPv4Address:
        return list(self.__dhcp_subnet.hosts())[0]

    @property
    def broadcast_address(self) -> ipaddress.IPv4Address:
        return self.network.broadcast_address

    @property
    def network(self) -> ipaddress.IPv4Network:
        return self.__network

    @property
    def interface_address(self) -> ipaddress.IPv4Interface:
        return ipaddress.IPv4Interface(f"{self.host_address}/{self.network.prefixlen}")

    @property
    def dhcp_hosts(self) -> typing.List[ipaddress.IPv4Address]:
        return list(self.__dhcp_subnet.hosts())[9:]

    def up(self):
        self.__was_managed, is_connected = self.nm_status()
        if self.__was_managed and is_connected:
            self.nm_disconnect()
        self.nm_unmanage()
        if list(interface_addresses(self.interface_name).keys()) != ["AF_PACKET"]:
            _LOGGER.warning(
                "interface %r is expected to have only OSI Layer 2 address, flushing all addresses",
                self.interface_name,
            )
            self.addr_flush()
        self.link_up()
        subprocess.check_call(
            [
                "ip",
                "addr",
                "add",
                str(self.interface_address),
                "brd",
                str(self.broadcast_address),
                "dev",
                self.interface_name,
            ],
            timeout=2,
        )

    def down(self):
        try:
            self.__link_cmd("down")
        finally:
            try:
                subprocess.check_call(
                    [
                        "ip",
                        "addr",
                        "del",
                        str(self.interface_address),
                        "dev",
                        self.interface_name,
                    ],
                    timeout=2,
                )
            finally:
                if self.__was_managed:
                    self.nm_unmanage()

    def __enter__(self):
        self.up()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.down()

    def __link_cmd(self, cmd) -> None:
        subprocess.check_call(
            [
                "ip",
                "link",
                "set",
                self.interface_name,
                cmd,
            ],
            timeout=2,
        )

    def __nmcli_manage_cmd(self, yes_or_no) -> None:
        if yes_or_no not in ["yes", "no"]:
            raise ValueError("invalid yes or no", yes_or_no)
        subprocess.check_call(
            [
                "nmcli",
                "device",
                "set",
                self.interface_name,
                "managed",
                yes_or_no,
            ],
            timeout=2,
        )

    def addr_flush(self) -> None:
        subprocess.check_call(
            [
                "ip",
                "addr",
                "flush",
                "dev",
                self.interface_name,
            ],
            timeout=2,
        )

    def set_forwarding(self, enabled: bool) -> None:
        with open(
            f"/proc/sys/net/ipv4/conf/{self.interface_name}/forwarding",
            "w",
            encoding="ascii",
        ) as forwarding_file:
            forwarding_file.write(str(int(enabled)))

    def enable_forwarding(self) -> None:
        self.set_forwarding(True)

    def disable_forwarding(self) -> None:
        self.set_forwarding(False)

    def link_up(self) -> None:
        self.__link_cmd("up")

    def link_down(self) -> None:
        self.__link_cmd("down")

    def nm_status(self) -> typing.Tuple[bool, bool]:
        lines = subprocess.check_output(
            [
                "nmcli",
                "-t",
                "device",
                "status",
            ],
            timeout=2,
        ).decode()
        for line in lines.splitlines():
            iface, _, state, connection = line.strip().split(":")
            if iface != self.interface_name:
                continue
            return state != "unmanaged", connection != ""
        return False, False

    def nm_manage(self) -> None:
        self.__nmcli_manage_cmd("yes")

    def nm_unmanage(self) -> None:
        self.__nmcli_manage_cmd("no")

    def nm_disconnect(self) -> None:
        subprocess.check_call(
            [
                "nmcli",
                "device",
                "disconnect",
                self.interface_name,
            ],
            timeout=10,
        )
