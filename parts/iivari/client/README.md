Iivari client
=============
Provides a custom stand-alone WebKit display.

See the [installation instructions in the wiki](/opinsys/iivari/wiki/Client-installation-instructions)


Test Suite
----------

Run the tests with nose (contains integration tests so ensure the iivari server is running):

      sudo apt-get install python-pip
      sudo pip install nose
      nosetests

Test the display hardware in offline mode:

      iivari-display_test_pattern


Copyright
=========

Copyright © 2011-2012 Opinsys Oy

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

