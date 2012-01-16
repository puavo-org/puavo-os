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
import __builtin__
from PySide import QtGui, QtCore, QtWebKit, QtNetwork
from PySide.QtWebKit import QWebSettings

from logging import getLogger
import iivari.logger
logger = getLogger(__name__)
from iivari import Display, Repl
from iivari.cookiejar import CookieJar


class MainWindow(QtGui.QMainWindow):
    """The main window consists of a single web view with JavaScript, HTML5 offline cache manifest and localStorage support.
    """
    webView = None
    
    def __init__(self, **kwargs):
        QtGui.QMainWindow.__init__(self)

        centralwidget = QtGui.QWidget(self)
        centralwidget.setObjectName("centralwidget")
        self.setCentralWidget(centralwidget)

        self.webView = MainWebView(centralwidget, **kwargs)


class MainWebView(QtWebKit.QWebView):
    
    display = None
    repl = None
    options = None
    
    def __init__(self, centralwidget, **kwargs):
        """MainWebView loads the page, and attaches interfaces to it.
        
        Keyword arguments:
          - url
          - hostname
          - use_repl

        NOTE: all QWebSettings must be set before setUrl() is called!
        """
        QtWebKit.QWebView.__init__(self, centralwidget)
        self.setObjectName("webView0")

        # store keyword arguments to options
        self.options = kwargs

        use_repl = self.options.get('use_repl')
        cache_path = __builtin__.IIVARI_CACHE_PATH

        # set custom WebPage to log JavaScript messages
        self.setPage(MainWebPage())

        # initialize REPL here to attach to console log early
        if use_repl is True:
            self.repl = Repl(page=self.page())

        # set custom NetworkAccessManager for cookie management and network error logging
        self.page().setNetworkAccessManager(MainNetworkAccessManager(cache_path))

        # attach a Display object to JavaScript window.display after page has loaded
        self.page().loadFinished[bool].connect(self.create_display)

        # use QWebSettings for this webView
        settings = self.settings()
        #settings = QWebSettings.globalSettings()

        # enable Javascript
        settings.setAttribute(QWebSettings.JavascriptEnabled, True)

        """
        Enable application to work in offline mode.
        Use HTML5 cache manifest for static content,
        and jquery.offline for dynamic JSON content.
        
        @see http://diveintohtml5.info/offline.html
        """
        settings.enablePersistentStorage(cache_path)
        # uncertain whether LocalContentCanAccessRemoteUrls is needed even when using offline cache
        # FIXME: check, and disable this if unneeded.
        settings.setAttribute(QWebSettings.LocalContentCanAccessRemoteUrls, True)
        
        #settings.setAttribute(
        #    QtWebKit.QWebSettings.DeveloperExtrasEnabled, True)
        
        # write settings to log
        logger.debug("\n * ".join([
            ' --- QWebSettings ---',
            'OfflineWebApplicationCache: %s' % (
                settings.testAttribute(
                    QWebSettings.OfflineWebApplicationCacheEnabled)),
            'LocalStorage: %s' % (
                settings.testAttribute(
                    QWebSettings.LocalStorageEnabled)),
            'offlineWebApplicationCachePath: %s' % (
                settings.offlineWebApplicationCachePath()),
            'offlineWebApplicationCacheQuota: %i' % (
                settings.offlineWebApplicationCacheQuota()),
            'LocalContentCanAccessRemoteUrls: %s' % (
                settings.testAttribute(
                    QWebSettings.LocalContentCanAccessRemoteUrls)),
            
            ]))

        # set URL and launch the request
        url = self.options.get('url')
        logger.info("url: %s" % url)
        self.setUrl(QtCore.QUrl(url))


    def create_display(self, ok):
        """Display is a JavaScript object proxy.

        It connects window.display JavaScript signals 
        to Python methods. 

        Python can also emit signals to JavaScript "slots"
        through this object.

        CoffeeScript-generated DisplayCtrl is another object,
        that is referred as window.displayCtrl. This Display
        object connects signals between these.
        """
        self.display = Display(self.page(), **self.options)
        # disconnect the signal once the display has first been created
        self.page().loadFinished.disconnect(self.create_display)
        # start REPL thread?
        if self.repl is not None:
            self.repl.run()


class MainWebPage(QtWebKit.QWebPage):

    def javaScriptConsoleMessage(self, message, lineNumber, sourceID):
        """Catches JavaScript console messages and errors from a QWebPage.
        
        Differentiates between normal messages and errors by matching 'Error' in the string.
        """
        msg_tmpl = '(%s:%i)\n%s' % (sourceID, lineNumber, '%s')

        # strip Warning, Info
        match = re.search('Info: (.*)',message)
        if match:
            logger.info(msg_tmpl % match.group(1))
            return

        match = re.search('Warning: (.*)',message)
        if match:
            logger.warn(msg_tmpl % match.group(1))
            return

        match = re.search('Error|Exception',message)
        if match:
            logger.error(msg_tmpl % message)
            return

        logger.debug(msg_tmpl % message)


    @QtCore.Slot()
    def shouldInterruptJavaScript(self):
        """Interrupt JavaScript execution (restarts process).
        
        This slot should be called when JavaScript
        execution seems to be taking too long.
        
        NOTE: this slot is called only in PySide >= 1.0.7.
        """
        pid = os.getpid()
        logger.fatal("interrupting JavaScript execution - killing pid %i" % pid)
        print " *\n * THIS CRASH IS INTENTIONAL! Please restart the application.\n *"
        os.kill(pid,9)
        return True


class MainNetworkAccessManager(QtNetwork.QNetworkAccessManager):
    """Logs possible network errors and handles the cookie jar."""

    def __init__(self, cache_path, cookiejar_file=None):
        QtNetwork.QNetworkAccessManager.__init__(self)

        if not cookiejar_file:
          cookiejar_file = os.path.join(cache_path, 'cookiejar.txt')

        # set custom cookie jar for persistance
        self.setCookieJar(CookieJar(cookiejar_file))
        self.finished[QtNetwork.QNetworkReply].connect(self._finished)

    @QtCore.Slot()
    def _finished(self, reply):
        """Logs possible network errors.
        
        After the request has finished, it is the responsibility of the user 
        to delete the PySide.QtNetwork.QNetworkReply object at an appropriate 
        time. Do not directly delete it inside the slot connected to 
        QNetworkAccessManager.finished().
        You can use the QObject.deleteLater() function.
        @see http://doc.qt.nokia.com/latest/qnetworkaccessmanager.html#details
        """
        try:
            #logger.debug("GET %s finished" % reply.request().url().toString())
            if not reply.error() == QtNetwork.QNetworkReply.NoError:
                logger.warn('Failed to GET "%s": %s' % (
                    reply.request().url().toString(), reply.error()))
            # NOTE: calling deleteLater() on the reply object
            # causes segmentation fault on Linux with Qt4.6 (and PySide 1.0.6).
            # Leaving the object to remain in memory may
            # cause a huge memory leak over time?
            # Qt4.7 does seem to behave better in this regard.
            if float(QtCore.__version__[0:3]) >= 4.7:
                reply.deleteLater()

        except Exception, e:
            logger.error(e)

