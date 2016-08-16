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
from PySide import QtCore
from logging import getLogger, StreamHandler, DEBUG
import iivari.logger
logger = getLogger(__name__)
try:
    import readline
except:
    logger.debug("no readline support")
    pass


class Repl(QtCore.QThread):
    """READ - EVAL - PRINT - LOOP JavaScript console.
    
    JavaScript is halted while waiting for input from user.
    """
    page = None
    console = None # StreamHandler
    _stopped = True

    def __init__(self, page):
        QtCore.QThread.__init__(self)
        self.page = page
        logger.info("Starting up JavaScript REPL")
        # configure console for logging
        # FIXME: at Repl restart (window.display.refresh()),
        # the loggers are initialized several times!
        self.console = StreamHandler()
        from logger.crc_logger import ConcurrentRotatingColoredLogger
        self.console.setFormatter(ConcurrentRotatingColoredLogger.debug_formatter())
        self.attach()
    
    def attach(self):
        """add console (STDERR) output stream at DEBUG level to iivari loggers"""
        for _logger in [getLogger(x) for x in [
            __name__,
            '__main__',
            'iivari.main',
            'iivari.display'
            ]]:
            _logger.addHandler(self.console)
            _logger.setLevel(DEBUG)
    
    def detach(self):
        """remove console (STDERR) output stream from iivari loggers"""
        for _logger in [getLogger(x) for x in [
            __name__,
            '__main__',
            'iivari.main',
            'iivari.display'
            ]]:
            _logger.removeHandler(self.console)
            _logger.setLevel(iivari.settings.LOG_LEVEL)

    def run(self):
        print """
Entering JavaScript shell. JavaScript execution is halted between commands.

    ^D to process JavaScript event stack,
    ^C to exit

Use "p input" prefix to wrap the input in console.log and see the output.

     > p Math
    [object Math]

     > var rnd = Math.random()
     > p rnd
    0.8141305467579514

You can call the display with the backend window.display signals,
and execute control data of window.displayCtrl.

     > window.display.powerOff()
     > window.display.powerOn()
     > window.display.refresh()
        """
        """ comment these out until server side code is merged to master
     > window.displayCtrl.getCtrlData()
     > window.displayCtrl.executeCtrlData()
     > window.displayCtrl.checkConnectivity()
        """
        self._stopped = False
        while not self._stopped:
            QtCore.QCoreApplication.processEvents()
            try:
                script = raw_input(' > ')
                # implement ruby-like "p" (as in print raw)
                # "method" for JavaScript console.log() wrapper
                if script[0:2] == 'p ':
                    script = "console.log( %s );" % script[2:]
                self.page.mainFrame().evaluateJavaScript(script)
            except EOFError:
                # signal ^D, roll loop to call processEvents()
                print
                continue
    
    def stop(self):
        logger.debug("exiting REPL")
        self.detach()
        self._stopped = True
        self.exit() # exit QThread
