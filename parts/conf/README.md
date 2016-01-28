# Puavo Conf

Puavo Conf is a database of parameters that control how a Puavo
host/device behaves. There is a library "libpuavoconf" that can be used
by programs, and a simple program "puavo-conf" that can be used to
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
`/usr/share/puavo/features/*/info.json`.  There should be files in
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

Here we define key "gnome" to be of type boolean and that has a default
value "false".

### settings from Puavo

Settings from Puavo are looked up from /etc/puavo/device.json, that
should contain key "features", like this:

{
  ...,
  "features": {
    "autopilot.mode": "off",
    "gnome": true
  }
  ...
}

Values specified here override the ones from image defaults.

### settings from hardware quirks database

Hardware quirks are looked from files that match the glob pattern
`/usr/share/puavo/hwquirks/*/*.json`.  These files are searched
in lexicographical order so that values with matched keys that are in
later files override the previously matched ones.  Each file has the
following kind of JSON-format (example):

[
  {
    "dmidecode-system-product-name": {
      "20D9S01U00": {
        "intel_backlight": true
      },
      "Aspire ES1-111": {
        "intel_backlight": true
      }
    }
  },
  {
    ":glob:": {
      "pci-id": {
        "0b8c:*": {
          "smartboard": true
        }
      }
    },
    ":regex:": {
      ...
    }
  }
]

Here we have a list of hashes that define how to map various hardware
parameters (such as `system-product-name` as returned by dmidecode)
to Puavo feature configurations.  In each hash we first have key that
tells that hardware characteristic that we are matching.  `dmidecode-*`
(with keywords supported by `dmidecode`) are supported, as well as
`pci-id` and `usb-id`.  Matching is exact by default, but special keywords
are recognized that affect the matching method: ":glob:" and ":regexp:"
are supported, and ":logic:" is also in the plans.  The value for special
keywords is a pattern/value hash just as in default exact matching.

### settings from primary user preferences

Not implemented yet.  (We should maybe also define somewhere
which values are overridable by primary user.)

### settings from kernel command-line arguments

Values set from kernel command-line override everything else.
Features can be set with `puavo.feature.key=value`, for example
`puavo.feature.gnome=false`.
