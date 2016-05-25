# Puavo Conf

Puavo Conf is the configuration system of Puavo OS. It consists of a
parameter database, a C library (`libpuavoconf`) and a set of programs
(`puavo-conf`, `puavo-conf-init` and `puavo-conf-update`) manipulating
the database through the library. Parameters define how various Puavo
OS components behave and can be tuned from multiple sources, such as
Puavo Web, local administrative tools or kernel command line.

## Buildtime dependencies

- libdb-dev
- libtool-bin

## Runtime dependencies

- dmidecode
- libdb5.3
- pciutils (lspci)
- ruby-ffi
- ruby1.9.1 or newer
- usbutils (lsusb)

## Building and installing

    make
    sudo make install

By default, files are installed to `/usr/local` prefix. To install to another
prefix, for example to `/usr`, run:

    make
    sudo make install prefix=/usr

`Makefile` supports also `DESTDIR=/path/to/install/dir` parameter for
staged installs. See
https://www.gnu.org/prep/standards/html_node/DESTDIR.html for more info.

## Usage

    puavo-conf-init         # create and populate a database
    puavo-conf              # list all keys and values
    puavo-conf key          # print the value of a key
    puavo-conf -b key       # print the value of a key, fail if it isn't bool
    puavo-conf key value    # set the value of a key
    puavo-conf -b key value # set the value of a key, fail if it is isn't bool

## Parameters

Parameters are key-value pairs. Both keys and values are stored in the
database as NUL-terminated strings. It is up to the user to decide how
to interpret parameter values.

Parameter values can be assigned from different sources with varying
precedences. The following list defines the currently supported sources
in ascending precedence order:

    1. Parameter definitions
    2. Parameter assignments from hardware quirks
    3. Parameter assignments from Puavo Web
    4. Parameter assignments from kernel command line

Thus, for example, values assigned on the kernel command line overwrite
values assigned by hardware quirks.

Parameter sources are read by `puavo-conf-init` in the given order and
together they construct the parameter database. The database must be
constructed before any configurable Puavo OS component is executing.

### Parameter definitions

Parameters must be defined in JSON files located in
`/usr/share/puavo-conf/definitions/*.json`. These files will be processed
in lexicographical order and must have the following structure:

    {
        "puavo.hosttype": {
            "typehint": "string",
            "choices": ["fatclient", "thinclient", "laptop"],
            "default": "fatclient",
            "description": "Type of the device"
        },
        "puavo.nethomes.enabled": {
            "typehint": "bool",
            "default": "true",
            "description": "Toggle network mounted home directories"
        },
        "puavo.nethomes.protocol": {
            "typehint": "string",
            "choices": ["nfs", "samba"],
            "default": "nfs",
            "description": "Network filesystem protocol used for network mounted home directories"
        }
    }

### Parameter overrides from hardware quirks

Hardware quirks must be defined in JSON files located in
`/usr/share/puavo-conf/hwquirk-overwrites/*.json`. These files will be processed
in lexicographical order and must have the following structure:

    [
        {
            "key": "dmidecode-system-product-name",
            "matchmethod": "exact",
            "pattern": "Aspire ES1-111",
            "parameters": {
                "puavo.intel_backlight": true
            }
        }
    ]

In this example, we enable intel_backlight on a specific Asus Aspire
device.

Field `key` determines the name of the hardware characteristic the
filter is matched against. Valid hardware characteristic key names are
`dmidecode-*` (wildcard expands to any keyword supported by
`dmidecode`), `pci-id` and `usb-id`. Field `matchmethod` determines
the method for matching: `exact`, `glob` and `regex` are
supported. Value is tested against the value of field `pattern`, and
if a match is successful, parameters listed in `parameters` field will
be set.

### Puavo Web

Currently, configuration definitions (`/etc/puavo/device.json` et al.)
from Puavo Web are converted to parameter assignments by
`puavo-conf-init`. In future, Puavo Web will support Puavo Conf
natively and just provide a list of parameter assignments to
configurable hosts.

### Kernel command line arguments

Parameter assignments from the kernel command line overwrite everything
else. Parameters can be assigned with the following syntax:
`puavo.parameter=value`.
