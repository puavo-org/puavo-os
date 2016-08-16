# -*- coding: utf-8 -*-
import unittest
import signal
import os
from logging import getLogger
logger = getLogger(__name__)

from PySide import QtCore, QtWebKit, QtNetwork
from iivari import Display
from iivari.settings import DISPLAYSTATUS_PATH

# add iivari bin directory into PATH
iivari_bin = os.path.abspath(os.path.join(os.path.dirname(__file__),'..','..','bin'))
os.environ['PATH'] = "%s:%s" % (iivari_bin, os.environ['PATH'])


class DisplayTests(unittest.TestCase):
    
    status_file = DISPLAYSTATUS_PATH

    def setUp(self):
        # Ctrl-C halts the test suite
        signal.signal( signal.SIGINT, signal.SIG_DFL )
        
    def tearDown(self):
        if os.path.exists(self.status_file):
            os.remove(self.status_file)

    def test_display(self):
        page = QtWebKit.QWebPage()
        display = Display(page, hostname="kiosk-01")
        self.assert_(display)

    def test_power_off(self):
        page = QtWebKit.QWebPage()
        display = Display(page, hostname="kiosk-01")
        if os.path.exists(self.status_file):
            os.remove(self.status_file)

        # trigger powerOff via JavaScript
        display.page.mainFrame().evaluateJavaScript(
            "window.display.powerOff()")
        QtCore.QCoreApplication.processEvents()

        self.assert_(os.path.exists(self.status_file), 'status file does not exist')
        f = open(self.status_file, 'r')
        status = f.read().strip()
        f.close()
        self.assertEquals('off', status)

    def test_power_on(self):
        page = QtWebKit.QWebPage()
        display = Display(page, hostname="kiosk-01")
        if os.path.exists(self.status_file):
            os.remove(self.status_file)

        # trigger powerOn via JavaScript
        display.page.mainFrame().evaluateJavaScript(
            "window.display.powerOn()")
        QtCore.QCoreApplication.processEvents()

        self.assert_(os.path.exists(self.status_file), 'status file does not exist')
        f = open(self.status_file, 'r')
        status = f.read().strip()
        f.close()
        self.assertEquals('on', status)


