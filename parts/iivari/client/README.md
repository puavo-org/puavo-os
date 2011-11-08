Iivari client
=============
Provides a custom WebKit browser for stand-alone kiosk display.

This is a replacement for the [stand-alone Chromium script](https://github.com/opinsys/iivari/wiki/Client-installation-instructions)

Software requirements

*   Python >= 2.6
*   PySide >= 1.0.0 (>= 1.0.7 preferred)
*   Qt >= 4.6

To install PySide on Ubuntu, enable the community repository and install the `python-pyside` meta-package. This will also pull all required Qt packages.

      sudo add-apt-repository ppa:pyside
      sudo apt-get update
      sudo apt-get install python-pyside

Setup
-----

Insert the server url into `iivari/settings.py`.

Run the tests with nose (contains integration tests so ensure the iivari server is running):

      sudo apt-get install python-pip
      sudo pip install nose
      nosetests

Test the display hardware in offline mode:

      bin/display-test-pattern.py

Start the kiosk slideshow:

      bin/iivari-kiosk.py

You may optionally specify kiosk hostname and screen resolution as input parameters. An interactive JavaScript console is also available in the REPL mode. See "`iivari-kiosk.py --help`" for usage.

For example:

      bin/iivari-kiosk.py -n kiosk1

Starts with the hostname "kiosk1".

* * *
**NOTE**: some built-in features will intentionally kill the client process.
This is for the OS to prevent possible memory leaks from happening if QWebView would be restarted programmatically inside the process.

**This leaves a requirement for a watchdog process restarting the client when it exits.**

Such as

      while (true); do bin/iivari-kiosk.py; done


Copyright
---------

Copyright © 2011 Opinsys Oy

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

