# Puavo Conf

Puavo Conf is the configuration system of Puavo OS. It consists of a
parameter database, a C library (`libpuavoconf`) and a set of programs
(`puavo-conf`, `puavo-conf-daemon` and `puavo-conf-update`) manipulating
the database through the library. Parameters define how various Puavo OS
components behave and can be tuned from multiple sources.

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
https://www.gnu.org/prep/standards/html_node/DESTDIR.html for more
info.

## Parameters

Parameters are key-value pairs. Both keys and values are stored as
NUL-terminated strings. It is up to the user to decide how to
interpret the values.

Parameter values can be assigned from different sources with varying
precedences. The following list defines the sources in ascending
precedence order:

    1. Parameter definitions
    2. Parameter overwrites from the image specific settings
    3. Parameter overwrites from the configuration profile
    4. Parameter overwrites from hardware quirks
    5. Parameter overwrites from device settings
    6. Parameter overwrites from the kernel command line

Thus, for example, values assigned on the kernel command line
overwrite values assigned by hardware quirks.

The configuration system is initialized by running `puavo-conf-update --init`,
which reads parameter definitions and creates new parameters with
default values.  The configuration can then be updated by running
`puavo-conf-update` which reads parameter overwrites and assigns new
values to parameters in the order defined above.

### Parameter definitions

Parameters must be defined in JSON files located in
`/usr/share/puavo-conf/definitions/*.json`. These files will be processed
in lexicographical order and must have the following structure:

    {
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

### Parameter overwrites from the image specific settings

Apply puavo-conf overwrites from `/etc/puavo-conf/image.json`
(which can be customized for various image).

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
          "puavo.intel_backlight.enabled": "true"
        }
      }
    ]

Field `key` determines the name of the hardware characteristic the
filter is matched against. Valid hardware characteristic key names are
`dmidecode-*` (wildcard expands to any keyword supported by
`dmidecode`), `pci-id` and `usb-id`. Field `matchmethod` determines
the method for matching: `exact`, `glob` and `regexp` are
supported.  Value is tested against the value of field `pattern`, and
if a match is successful, parameters listed in `parameters` field will
be set.  Parameter values must be strings.

### Puavo Web

Currently, configuration definitions (`/etc/puavo/device.json` et al.)
from Puavo Web are converted to parameter assignments by
`puavo-conf-update --init`. In future, Puavo Web will support
Puavo Conf natively and just provide a list of parameter assignments
to configurable hosts.

### Kernel command line arguments

Parameter assignments from the kernel command line overwrite everything
else. Parameters can be assigned with the following syntax:
`puavo.parameter=value`.
