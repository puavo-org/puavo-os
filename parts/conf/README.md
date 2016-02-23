# Puavo Conf

Puavo Conf is the configuration system of Puavo OS. It consists of a
parameter database, a C library (`libpuavoconf`) and a set of programs
(`puavo-conf` and `puavo-conf-mkdb`) manipulating the database through
the library. Parameters define how various Puavo OS components behave
and can be tuned from multiple sources, such as Puavo Web, local
administrative tools or kernel command line.

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

## Building

    make
    sudo make install

By default, builds are targeted to `/usr/local` prefix. To make a build
targeted to `/usr` instead, run:

    make prefix=/usr
    sudo make install

`Makefile` supports also `DESTDIR=/path/to/install/dir` parameter for
staged installs. See
https://www.gnu.org/prep/standards/html_node/DESTDIR.html for more info.

## Usage

    puavo-conf-mkdb      # create and populate a database
    puavo-conf           # list all keys and values
    puavo-conf key       # print the value of a key
    puavo-conf key value # set the value of a key

## Parameters

Parameters are key-value pairs. Both keys and values are stored in the
database as NUL-terminated strings. It is up to the user to decide how
to interpret parameter values.

Parameter values can be assigned from different sources with varying
precedences. The following list defines the currently supported sources
in ascending precedence order:

    1. Parameter definitions
    2. Parameter assignments from parameter filters
    3. Parameter assignments from hardware quirks
    4. Parameter assignments from Puavo Web
    5. Parameter assignments from local configuration
    6. Parameter assignments from kernel command line

Thus, for example, values assigned on the kernel command line overwrite
values assigned by hardware quirks.

Parameter sources are read by `puavo-conf-mkdb` in the given order and
together they construct the parameter database. The database must be
constructed before any configurable Puavo OS component is executing.

### Parameter definitions

Parameters must be defined in JSON files located in
`/usr/share/puavo-conf/parameters/*.json`. These files will be processed
in lexicographical order and must have the following structure:

    {
        "puavo.hosttype": {
            "type": "string",
            "choices": ["fatclient", "thinclient", "laptop"],
            "default": "fatclient",
            "description": "Type of the device"
        },
        "puavo.nethomes.enabled": {
            "type": "bool",
            "default": true,
            "description": "Toggle network mounted home directories"
        },
        "puavo.nethomes.protocol": {
            "type": "string",
            "choices": ["nfs", "samba"],
            "default": "nfs",
            "description": "Network filesystem protocol used for network mounted home directories"
        }
    }

### Parameter filters

It is possible to overwrite default parameter values with parameter
filters. Filters must be defined in JSON files located in
`/usr/share/puavo-conf/filters/*.json`. These files will be processed in
lexicographical order and must have the following structure:

    [
        {
            "key": "puavo.hosttype",
            "matchmethod": "exact",
            "pattern": "laptop",
            "parameters": {
                "puavo.nethomes.enable": false
            }
        },
        {
            "key": "puavo.hosttype",
            "matchmethod": "exact",
            "pattern": "fatclient",
            "parameters": {
                "puavo.nethomes.enable": true,
                "puavo.nethomes.protocol": "nfs"
            }
        }
    ]

In the above example, two filters are defined which disable network
mounted home directories on laptops and enable on fatclients using NFS,
respectively.

Field `key` determines the name of the parameter the filter is matched
against. Field `matchmethod` determines the method for matching:
`exact`, `glob` and `regex` are supported. Value is tested against the
value of field `pattern`, and if a match is successful, parameters
listed in `parameters` field will be set.

### Parameter overrides from hardware quirks

Hardware quirks must be defined in JSON files located in
`/usr/share/puavo-conf/hwquirks/*.json`. These files will be processed
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

In contrast to parameter filters, here `key` determines the name of the
*hardware characteristic* the filter is matched against. Valid hardware
characteristic key names are `dmidecode-*` (wildcard expands to any keyword
supported by `dmidecode`), `pci-id` and `usb-id`.

### Puavo Web

Currently, configuration definitions (`/etc/puavo/device.json` et al.)
from Puavo Web are converted to parameter assignments by
`puavo-conf-mkdb`. In future, Puavo Web will support Puavo Conf natively
and just provide a list of parameter assignments to configurable hosts.

### Local configuration

Not implemented yet.

### Kernel command line arguments

Parameter assignments from the kernel command line overwrite everything
else. Parameters can be assigned with the following syntax:
`puavo.parameter=value`.
