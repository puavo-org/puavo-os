# Puavo Conf

Puavo Conf is a database of parameters that control how a Puavo
host/device behaves. There is a library `libpuavoconf` that can be used
by programs, and a simple program `puavo-conf` that can be used to
get/set values on database. Database consists of key/value-pairs. Both
keys and values are character strings (can not contain NUL-byte).

## Build dependencies

- libdb-dev
- libtool-bin

## Building

By default, builds are targeted to `/usr/local` prefix. To make a build
targeted to `/usr` instead, run:

    make prefix=/usr
    sudo make install

## Usage

    puavo-conf key       # retrieves value for key
    puavo-conf key value # sets the value of key to "value"

    puavo-conf-mkdb      # creates puavo-conf database for this host

## `puavo-conf-mkdb` sources and source formats

`puavo-conf-mkdb` reads feature configuration parameters from various
sources and constructs a puavo-conf database from those.  This database
is customized for each host and runtime.  Normally `puavo-conf-mkdb`
should be run at an boottime.

`puavo-conf-mkdb` looks up these sources in this order:

    1. image defaults
    2. feature-profiles
    3. hardware quirks database
    4. settings from puavo
    5. primary user preferences (currently unimplemented)
    6. kernel arguments

Values set by later sources override values set by previous ones.  Thus,
for example, settings set in kernel arguments overwrite settings from
hardware quirks database.

### settings from image defaults

Default image values are looked from files that match the glob pattern
`/usr/share/puavo-conf/parameters/*.json`. There should be files in
JSON-format like this:

    {
      "keys": {
        "gnome": {
          "default": false,
          "description": "Gnome desktop environment",
          "type": "boolean"
        }
      }
    }

Here we define key `gnome` to be of type boolean and that has a default
value `false`.

### feature profiles

It is possible to write feature profiles to
`/etc/puavoimage/feature-profiles.json`.  This is a feature template
file with the following JSON-format:

    [
      {
        "key": "hosttype",
        "matchmethod": "exact",
        "pattern": "thinclient",
        "profile": {
          "nfshomes": "false"
        }
      }
    ]

`key` determines the parameter key that is used to look up parameters
from Puavo-settings and kernel arguments (kernel arguments override
Puavo-settings).  Key `matchmethod` determines the method for matching:
`exact`, `glob` and `regex` are supported.  Value is tested against the
value set in `pattern`, and if a match is successful, settings under
`profile` are put to use.

For example, if we provide `puavo.feature.infotv=true` on kernel
command-line, with the above configuration also `gnome` will
be set to `false` (unless some other settings that have priority
will override that).

### settings from hardware quirks database

Hardware quirks are looked from files that match the glob pattern
`/usr/share/puavo-conf/hwquirks/*.json`. These files are searched
in lexicographical order so that values with matched keys that are in
later files override the previously matched ones.  Each file is a feature
template file that has the same format as in feature profiles,
except keys are not matched against Puavo-settings and kernel-arguments
but against device characteristics.  For example:

    [
      {
        "key": "dmidecode-system-product-name",
        "matchmethod": "exact",
        "pattern": "20D9S01U00",
        "profile": {
          "intel_backlight": true
        }
      },
      {
        "key": "dmidecode-system-product-name",
        "matchmethod": "exact",
        "pattern": "Aspire ES1-111",
        "profile": {
          "intel_backlight": true
        }
      },
      {
        "key": "pci-id",
        "matchmethod": "glob",
        "pattern": "8086:*",
        "profile": {
          "guestlogin": true,
          "intel_backlight": true
        }
      }
    ]

In each hash we have `key` whose value tells the hardware characteristic
we are matching.  `dmidecode-*` (with keywords supported by `dmidecode`)
are supported, as well as `pci-id` and `usb-id`.  Otherwise the behaviour
is the same as with feature profiles.  These settings will override
values set in feature profiles.

### settings from Puavo

Settings from Puavo are looked up from `/etc/puavo/device.json`, that
should contain key "features", like this:

    {
      ...,
      "features": {
        "autopilot.mode": "off",
        "gnome": true
      }
      ...
    }

Values specified here override the settings in previous sections.

### settings from primary user preferences

Not implemented yet.  (We should maybe also define somewhere
which values are overridable by primary user.)

### settings from kernel command-line arguments

Values set from kernel command-line override everything else.
Features can be set with `puavo.feature.key=value`, for example
`puavo.feature.gnome=false`.
