# -*- coding: utf-8 -*-
import unittest
import signal
import os, sys
import urllib2
from urlparse import urlsplit
from time import sleep
from logging import getLogger
logger = getLogger(__name__)

from PySide import QtCore, QtNetwork
from iivari.main import MainNetworkAccessManager
from iivari.cookiejar import CookieJar
from iivari.settings import SERVER_BASE

from iivari.tests import QT_APP

class CookieJarTests(unittest.TestCase):

    cookiejar_file = 'cookiejar_test.txt'
    server = None
    
    def setUp(self):
        # Ctrl-C halts the test suite
        signal.signal( signal.SIGINT, signal.SIG_DFL )
        # server should be online for these (integration) tests
        _url = urlsplit(SERVER_BASE)
        self.server = "%s://%s" % (_url.scheme, _url.netloc)
        url = self.server+'/'
        request = urllib2.Request(url)
        request.get_method = lambda : 'HEAD'
        try:
            response = urllib2.urlopen(request)
        except:
            self.fail(sys.exc_info()[1])

    def tearDown(self):
        if os.path.exists(self.cookiejar_file):
            os.remove(self.cookiejar_file)
    
    def _exec_request__return_cookies(self, url):
        # use test txt file to store cookies
        nm = MainNetworkAccessManager(cookie_path=self.cookiejar_file)
        self.assert_(nm)
        request = QtNetwork.QNetworkRequest(url=QtCore.QUrl(url))
        # execute an actual request to the server
        reply = nm.get(request)
        # QtApplication instance needs to be started for the request,
        # but ensure the execution is returned to the test
        nm.finished.connect(QT_APP.quit)
        QT_APP.exec_()
        jar = nm.cookieJar()
        return jar.allCookies()


    def test_jar(self):
        """Create cookie"""
        _jar = CookieJar(self.cookiejar_file)
        self.assert_(_jar)
    
    def test_unauthorized(self):
        """error 401"""
        url = self.server+'/ping'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(0, len(cookies))

    def test_ping(self):
        """ping live server"""
        url = self.server+'/ping'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(0, len(cookies))

    def test_displayauth(self):
        url = self.server+'/displayauth?hostname=kiosk'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(1, len(cookies))

    def test_conductor(self):
        url = self.server+'/conductor?hostname=kiosk'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(1, len(cookies))

    def test_slides_json(self):
        url = self.server+'/displayauth?hostname=kiosk'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(1, len(cookies))
        # authenticated, now the actual request
        url = 'http://localhost:3000/slides.json'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(1, len(cookies))

    def test_jar_persistance_integration(self):
        """Cookie is persisted (with live server)"""
        url = self.server+'/displayauth?hostname=kiosk'
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(1, len(cookies))
        iivari_session_cookie = cookies[0]
        # FIXME: enable this assertion after server on master is updated
        #self.assertEquals('_iivari_session', str(iivari_session_cookie.name()))

        # session1 is the session value.
        # Currently Iivari uses cookie_store for session_store,
        # so the session contents is encoded to cookie string
        session1 = iivari_session_cookie.value().__str__()

        # execute a second request, session should not change
        cookies = self._exec_request__return_cookies(url)
        self.assertEquals(session1, cookies[0].value().__str__())
        
