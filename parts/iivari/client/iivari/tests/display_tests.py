# -*- coding: utf-8 -*-
import unittest
import signal
import os
from logging import getLogger
logger = getLogger(__name__)

from PySide import QtCore, QtWebKit, QtNetwork
from iivari import Display

class DisplayTests(unittest.TestCase):
    
    bin_dir = os.path.join(os.path.dirname(__file__),'..','..','bin')
    status_file = os.path.join(os.environ['HOME'], '.iivari', 'power-status')

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
        display = Display(page, hostname="kiosk-01", bin_dir=self.bin_dir)
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
        display = Display(page, hostname="kiosk-01", bin_dir=self.bin_dir)
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


