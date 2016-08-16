# -*- coding: utf-8 -*-
"""
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
"""
import sys
import signal
import urlparse
from optparse import OptionParser
from logging import getLogger
import PySide
import iivari

def process_args():
    parser = OptionParser()
    parser.add_option(
        "-n", "--hostname", action="store", dest="hostname",help="kiosk hostname for the server (overrides autodetect)")
    parser.add_option(
        "-s", "--size", action="store", dest="size",help="kiosk screen resolution (overrides autodetect)")
    parser.add_option(
        "-r", "--repl", action="store_true", dest="use_repl",help="launch JavaScript REPL for debugging")
    parser.add_option("-u", "--urlbase", action="store", dest="urlbase",
                      help="base for url to fetch screen contents")

    return parser.parse_args()


if __name__ == "__main__":
    """Iivari-kiosk startup.

    Invoke from the command line:

        $ python -m iivari.kiosk [args]

    """
    logger = getLogger(__name__)

    # ensure that the application quits using CTRL-C
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    # parse command line parameters
    (opts, args) = process_args()

    # Prints PySide and the Qt version used to compile PySide
    logger.info(' *\n * Initialising iivari-kiosk %s\n * PySide version %s\n * Qt version %s\n *' % (
        iivari.__version__,
        PySide.__version__,
        PySide.QtCore.__version__))

    # initialize Qt application and MainWindow
    app = PySide.QtGui.QApplication(sys.argv)

    # process parameters
    # --hostname
    if opts.hostname is not None:
        hostname = opts.hostname
    else:
        import socket
        hostname = socket.gethostname()
    # --repl
    use_repl = opts.use_repl
    # --size
    if opts.size is not None:
        # resolution is given in string format widthxheight
        # (eg. "800x600")
        (width, height) = [int(d) for d in opts.size.split('x')]
    else:
        size = app.desktop().availableGeometry().size()
        width = size.width()
        height = size.height()

    # format start url
    base = urlparse.urlsplit(opts.urlbase or iivari.settings.SERVER_BASE)
    resolution = "%dx%d" % (width, height)
    params = 'resolution=%s&hostname=%s' % (resolution, hostname)
    url = urlparse.urlunsplit(urlparse.SplitResult(base.scheme,
                                                   base.netloc,
                                                   base.path,
                                                   params,
                                                   ''))

    # create the main window
    window = iivari.MainWindow(
        url=url,
        hostname=hostname,
        use_repl=use_repl,
        )

    # set fullscreen mode and resize the WebView to proper resolution
    window.showFullScreen()
    window.webView.setGeometry(PySide.QtCore.QRect(0, 0, width, height))

    # show the window
    window.show()
    # raise it to the front
    window.raise_()

    # start application and quit on exit
    logger.debug("Initialization complete. Launching application.")
    sys.exit(app.exec_())

