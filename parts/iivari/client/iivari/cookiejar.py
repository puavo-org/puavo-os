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
import os, re
from PySide import QtNetwork

from logging import getLogger, StreamHandler, DEBUG
import iivari.logger
logger = getLogger(__name__)


class CookieJar(QtNetwork.QNetworkCookieJar):
    
    cookiejar_file = None
    
    def __init__(self, cookiejar_file):
        QtNetwork.QNetworkCookieJar.__init__(self)
        self.cookiejar_file = cookiejar_file

        # create cookiejar file unless it exists
        if not os.path.exists(self.cookiejar_file):
            open(self.cookiejar_file, 'w').close()
        else:
            try:
                # read cookies from file
                f = open(self.cookiejar_file,'r')
                cookies = QtNetwork.QNetworkCookie.parseCookies(
                    f.read())
                f.close()
                self.setAllCookies(cookies)
                if len(cookies) > 0:
                    logger.info('read %d cookies from "%s"' % (
                        len(cookies), self.cookiejar_file))
            except (IOError, TypeError), e:
                logger.warn('Error while restoring cookies from "%s": %s' % (self.cookiejar_file, e))


    def setCookiesFromUrl(self, cookieList, url):
        # logger.debug('?set cookies for %s' % url)
        _url = url.toString()
        # discard cookies unless url matches one of:
        # /displayauth, /conductor, /slides.json, 
        # /display_ctrl.json, /screen.manifest
        if not re.search(
            r'/displayauth|/conductor|/slides\.json|/display_ctrl\.json|/screen\.manifest',
            _url):
            # logger.debug("nay")
            return False

        # cookies accepted
        # logger.debug("ay")
        try:
            cookies_to_store = []
            for cookie in cookieList:
                # do not store session cookies
                if not cookie.isSessionCookie():
                    cookies_to_store.append(cookie.toRawForm().__str__())
            # logger.debug(_url +" : "+ ", ".join(cookies_to_store))
            # save to file
            f = open(self.cookiejar_file,'w')
            f.write("\n".join(cookies_to_store))
            f.close()
            logger.debug('stored %d cookie(s) from "%s"' % (
                len(cookies_to_store), _url))
            # publish cookies to Qt
            self.setAllCookies(cookieList)

        except Exception, e:
            logger.error(e)
            return False
        return True


    def cookiesForUrl(self, url):
        return self.allCookies()
        
