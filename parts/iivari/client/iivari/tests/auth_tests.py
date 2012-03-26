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
            payload = {"username": username, "password": password}
            data = urllib.urlencode(payload)
            url = self.urlbase + "authkey/verify"
            token = hostname+":"+hashlib.sha1(hostname+":"+key).hexdigest()
            request = urllib2.Request(url, data, {'X-Iivari-Auth': token})
            response = urllib2.urlopen(request)
            self.assertEquals(response.read(), "ok")
            return key
        except urllib2.HTTPError, e:
            self.fail(e)


    def test_unauthorized(self):
        """Should unauthorize without proper session key."""
        url = self.urlbase + "conductor"
        # corrupt key
        f = open(self.authkey_file, 'w')
        f.write("XXXXXXXX")
        f.close()
        view = MainWebView(None, url=url, hostname=self.hostname)

        def callback(reply):
            status = reply.attribute(QtNetwork.QNetworkRequest.HttpStatusCodeAttribute)
            self.assertEquals(status, 401)
            QT_APP.quit()

        nm = view.page().networkAccessManager()
        nm.finished[QtNetwork.QNetworkReply].connect(callback)
        QT_APP.exec_()


    def test_authenticate_conductor(self):
        url = self.urlbase + "conductor"
        view = MainWebView(None, url=url, hostname=self.hostname)

        def callback(reply):
            nm.finished[QtNetwork.QNetworkReply].disconnect(callback)
            status = reply.attribute(QtNetwork.QNetworkRequest.HttpStatusCodeAttribute)
            self.assertEquals(status, 200)
            QT_APP.quit()

        nm = view.page().networkAccessManager()
        nm.finished[QtNetwork.QNetworkReply].connect(callback)
        QT_APP.exec_()


    def test_authenticate_slides_ajax(self):
        """Test AJAX authentication."""
        url = self.urlbase + "ping" # regular GET
        view = MainWebView(None, url=url, hostname=self.hostname)

        class Finish(QtCore.QObject, unittest.TestCase):
            """Ajax ready callback"""
            @QtCore.Slot()
            def finish(self):
                status = view.page().mainFrame().toPlainText()
                self.assertEquals(status, '200')
                QT_APP.quit()

        def callback(reply):
            """HTML callback"""
            nm.finished[QtNetwork.QNetworkReply].disconnect(callback)
            view.page().mainFrame().addToJavaScriptWindowObject("finish", Finish())
            view.page().mainFrame().evaluateJavaScript("""
                var url = "%s";
                var xhr = new XMLHttpRequest();
                xhr.open("GET", url, false);
                xhr.onreadystatechange = function() {
                    if (xhr.readyState == 4) {
                        console.log("READY");
                        document.body.innerHTML = xhr.status;
                        finish.finish();
                    }
                };
                console.log("send ajax");
                xhr.send("");
                """ % (self.urlbase + "slides.json")) # ajax url

        nm = view.page().networkAccessManager()
        nm.finished[QtNetwork.QNetworkReply].connect(callback)
        QT_APP.exec_()

