#!/usr/bin/env python
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
import os, sys
import re
from time import time
from subprocess import Popen, PIPE
from PySide import QtGui, QtCore, QtWebKit, QtNetwork
from logging import getLogger
import iivari.logger
logger = getLogger(__name__)


class Display(QtCore.QObject):
    """JavaScript window and Python messaging object."""
    
    page = None
    hostname = None
    # save startup time to check later when refresh signal is called.
    startup_time = time()
    
    def __init__(self, page, **kwargs):
        QtCore.QObject.__init__(self)
        self.page = page
        self.hostname = kwargs.get('hostname')

        # add the proxy object "display" to window
        self.page.mainFrame().addToJavaScriptWindowObject("display", self)

        # set the kiosk hostname
        self.page.mainFrame().evaluateJavaScript(
            """
            if (window.displayCtrl) {
                window.displayCtrl.hostname = "%s";
            }
            else {
                // waiting for server-side components to make it to master
                //console.log("no window.displayCtrl");
            }
            """ % self.hostname)

        self.powerOn()
        logger.debug("Initialised Display %s" % self.hostname)


    @QtCore.Slot()
    def refresh(self):
        """Refresh the webView and update cache.

        The refresh signal will kill the running process, which hopefully will
        be restored by a background daemon in production environment.
        The refresh signal will not activate if the process has been alive less
        than 10 minutes. This is the time frame in which the JavaScript 
        display control will send this signal for a given timer.
        
        The offline cache will not cleared.
        For the JavaScript and other assets to be updated, the manifest revision
        needs to be updated.

        First attempted to do soft reload, by
            self.page().triggerAction(QtWebKit.QWebPage.ReloadAndBypassCache, True)
        ..but the newly loaded pages were not cached anymore.
        Perhaps this would work by calling window.applicationCache.update()
        followed by window.applicationCache.swapCache() ?
        """
        time_alive = time() - self.startup_time
        if time_alive > 600:
            # if process has been up for more than 10 minutes, kill pid
            self.forceRefresh()
        else:
            logger.debug("ignoring refresh signal - booted less than 10 minutes ago")

    @QtCore.Slot()
    def forceRefresh(self):
        """Kills the client process."""
        # expect someone to catch and restart this poor kill -9'd fella
        pid = os.getpid()
        logger.fatal("refresh display - killing pid %i" % pid)
        print " *\n * THIS CRASH IS INTENTIONAL! Please restart the application.\n *"
        os.kill(pid,9)

    @QtCore.Slot()
    def powerOn(self):
        """Power on the display."""
        self._runscript("iivari-display_on")

    @QtCore.Slot()
    def powerOff(self):
        """Power off the display."""
        self._runscript("iivari-display_off")

    def _runscript(self, scriptname):
        """Execute a shell script
        """
        logger.debug("executing script %s" % scriptname)
        try:
            p = Popen(scriptname,
		      shell=False,
		      stdin=PIPE,
		      stdout=PIPE,
		      stderr=PIPE)
            stdout, stderr = p.communicate()
            if len(stdout) > 0:
                logger.debug(stdout)
            if len(stderr) > 0:
                # it is quite annoying to get the xset usage
                # constantly flooding the debug log
                #logger.error(stderr)
                logger.warn(stderr[0:36])
        except Exception, e:
            logger.error(e)
