# puavo-tftp

puavo-tftp is a dynamic read-only [TFTP][] server. It's dynamic in a sense it
can be configured to execute script hooks for a set of matched files on read
requests (RRQ) instead of reading files from the file system. The standard
output of the script will be used as the file content for those read requests.

## Configuration

Configuration file is read from `/etc/puavo-tftp.yml` by default. You can
customize it with `--config` switch. The file is in [YAML][] format.

  - `root`: Serve file files from this root. Default: `/var/lib/tftpboot/`
  - `user`: If started as root drop to this user.
  - `group`: If started as root drop to this grop.
  - `verbose`: Set to true to enable debug logging.
  - `port`: Listen on port. Default: 69
  - `hooks`: See the next paragraph

### Dynamic files with hooks

The `hooks` option is a list of associative arrays with `regexp` and `command`
keys. The given regular expression will be matched against incoming read
requests (RRQ). On match the command will be executed with the requested file
as the first argument instead of reading the file from the file system. The
standard output of the command will be sent to the client requesting the file.

Matching is stopped on the first matched regexp. If no matches are found the
file is read from the file system like in normal tftp servers.

#### Example

Return custom boot config for each LTSP client using a custom web service.

Match mac address based pxelinux.cfg read requests in `/etc/puavo-tftp.yml`:

```yaml
hooks:
  - regexp: pxelinux.cfg\/01-(([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2})
    command: get-boot-config
```

`get-boot-config` is script like this in the PATH:

```sh
#!/bin/sh

# First argument constains the requested file path
RRQ=$1

wget \
    # Disable wget debug output
    --quiet \
    # Write fetched file to standard output for puavo-tftp
    --output-document=-
    "http://example.net/bootconfig/$RRQ"
```

## CLI switches

CLI switches can be used to override options in `puavo-tftp.yml`.

    Usage: [sudo] puavo-tftpd [options]
        -r, --root PATH                  Serve files from directory.
        -u, --user USER                  Drop to user.
        -g, --group GROUP                Drop to group. Default nogroup
        -c, --config FILE                Configuration file. Default /etc/puavo-tftp.yml
            --verbose                    Print more debugging stuff.
        -p, --port PORT                  Listen on port.


## Install

On Precise Pangolin

    sudo apt-get install ruby1.9.3 ruby-eventmachine libldap-ruby1.8

    make install

To install it with hooks:

    make install INSTALL_HOOKS=yes


## Tests

Install minitest

    sudo apt-get install ruby-minitest

Run

    make test

## Copyright

Copyright © 2013 Opinsys Oy

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

[TFTP]: http://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol
[YAML]: http://en.wikipedia.org/wiki/YAML

