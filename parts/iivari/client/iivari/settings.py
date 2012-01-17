# -*- coding: utf-8 -*-
#
# Iivari settings
#
from logging import FATAL, WARN, INFO, DEBUG
import os

# server URL
SERVER_URL = "http://localhost:3000"

# base log and cache default root to repository main directory
IIVARIDIR = os.path.join(os.environ['HOME'], '.iivari')

# display status file path
DISPLAYSTATUS_PATH = os.path.join(IIVARIDIR, 'power-status')

# cache directory. leave undefined to disable caching.
CACHE_PATH = os.path.join(IIVARIDIR, 'cache')

# cookiejar file path. must be defined when cache is enabled.
COOKIE_PATH = os.path.join(CACHE_PATH, 'cookiejar.txt')

# log file location. leave undefined for console output.
LOG_FILE = os.path.join(IIVARIDIR, 'log', 'iivari.log')

# logger level -- FATAL, WARN, INFO, DEBUG
LOG_LEVEL = DEBUG

# use fancy shell coloring in log?
LOG_COLORS = True
