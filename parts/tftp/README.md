# TFTP server

### Dependencies

On Precise Pangolin

    sudo apt-get install ruby1.9.3 ruby-eventmachine libldap-ruby1.8

### Install

    make install

To install it with hooks:

    make install INSTALL_HOOKS=yes

### Usage

    Usage: [sudo] puavo-tftpd [options]
        -r, --root PATH                  Serve files from directory.
        -u, --user USER                  Drop to user.
        -g, --group GROUP                Drop to group. Default nogroup
        -c, --config FILE                Configuration file
            --verbose                    Print more debugging stuff.
        -p, --port PORT                  Listen on port.


### Tests

Install minitest

    sudo apt-get install ruby-minitest

Run

    make test

### Copyright

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
