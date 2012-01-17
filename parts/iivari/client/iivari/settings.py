# -*- coding: utf-8 -*-
#
# Iivari settings
#
from logging import FATAL, WARN, INFO, DEBUG
import os

# server URL
SERVER_URL = "http://localhost:3000"

# logger level -- FATAL, WARN, INFO, DEBUG
LOG_LEVEL = DEBUG

# use fancy shell coloring in log?
LOG_COLORS = True

# base log and cache default root to repository main directory
IIVARIDIR = os.path.join(os.environ['HOME'], '.iivari')

# display status file path
DISPLAYSTATUS_PATH = os.path.join(IIVARIDIR, 'power-status')

# cache directory
CACHE_PATH = os.path.join(IIVARIDIR, 'cache')
#CACHE_PATH = '/var/run/iivari'

# cookiejar file path
COOKIE_PATH = os.path.join(CACHE_PATH, 'cookiejar.txt')

# log dir and file location
# set None for console output
LOG_FILE = os.path.join(IIVARIDIR, 'log', 'iivari.log')
#LOG_FILE = None
#LOG_FILE = '/var/log/iivari.log'
