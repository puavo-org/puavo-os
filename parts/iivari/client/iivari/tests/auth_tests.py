# -*- coding: utf-8 -*-
import unittest
import signal
import os, sys
import urllib, urllib2, hashlib
from urlparse import urlsplit
from time import sleep
from PySide import QtCore, QtNetwork, QtWebKit
from iivari import settings
from iivari.main import MainWebView, MainNetworkAccessManager
from iivari.tests import QT_APP
from logging import getLogger
logger = getLogger(__name__)


class AuthenticationTests(unittest.TestCase):
    """Test server authentication. Requires live server.

    NOTE: Qt may segfault when running the whole suite,
    but will not if tests are run separately.

    """

    authlogic_username = "Test User" # used to generate new key!
    authlogic_userpass = "test"
    hostname = "test.host"
    urlbase = None
    authkey_file = 'authkey_test.txt'

    def setUp(self):
        # Ctrl-C halts the test suite
        signal.signal( signal.SIGINT, signal.SIG_DFL )

        _url = urlsplit(settings.SERVER_BASE)
        self.urlbase = "%s://%s/" % (_url.scheme, _url.netloc)

        # in production setup this key is saved on file 
        key = self.generate_and_verify_key(
            username=self.authlogic_username,
            password=self.authlogic_userpass,
            hostname=self.hostname)
        self.assertEquals(len(key), 10)
        f = open(self.authkey_file, 'w')
        f.write(key)
        f.close()
        settings.AUTHKEY_FILE = self.authkey_file

    def tearDown(self):
        if os.path.exists(self.authkey_file):
            os.remove(self.authkey_file)

    def generate_and_verify_key(self, username, password, hostname):
        """Calls Iivari server REST API to generate and verify new session key.
        """
        try:
            # Retrieve key
            payload = {"username": username, "password": password, "hostname": hostname}
            data = urllib.urlencode(payload)
            url = self.urlbase + "authkey/generate"
            request = urllib2.Request(url, data)
            response = urllib2.urlopen(request)
            key = response.read()

            # Verify
            url = self.urlbase + "authkey/verify"
            token = hostname+":"+hashlib.sha1(hostname+":"+key).hexdigest()
            request = urllib2.Request(url, "", {'X-Iivari-Auth': token})
            response = urllib2.urlopen(request)
            self.assertEquals(response.read(), "ok")
            return key
        except urllib2.HTTPError, e:
            self.fail(e)


    def test_unauthorized(self):
        """Should unauthorize without proper session key."""
        url = self.urlbase + "authkey/verify"
        # corrupt key
        f = open(self.authkey_file, 'w')
        f.write("XXXXXXXX")
        f.close()
        view = MainWebView(None, url=url, hostname=self.hostname)
        def callback(reply):
            status = reply.attribute(QtNetwork.QNetworkRequest.HttpStatusCodeAttribute)
            QT_APP.quit()
            self.assertEquals(status, 401)
        nm = view.page().networkAccessManager()
        nm.finished[QtNetwork.QNetworkReply].connect(callback)
        QT_APP.exec_()

    def test_verify(self):
        url = self.urlbase + "authkey/verify"
        view = MainWebView(None, url=url, hostname=self.hostname)
        def callback(reply):
            status = reply.attribute(QtNetwork.QNetworkRequest.HttpStatusCodeAttribute)
            QT_APP.quit()
            self.assertEquals(status, 200)
        nm = view.page().networkAccessManager()
        nm.finished[QtNetwork.QNetworkReply].connect(callback)
        QT_APP.exec_()

