# -*- coding: utf-8 -*-
#
# Iivari settings
#
import os, json, re, logging

# base log and cache default root to repository main directory
IIVARIDIR = os.path.join(os.environ['HOME'], '.iivari')

# display status file path
DISPLAYSTATUS_PATH = os.path.join(IIVARIDIR, 'power-status')

# cache directory. leave undefined to disable caching.
CACHE_PATH = os.path.join(IIVARIDIR, 'cache')

# cookiejar file path. must be defined when cache is enabled.
COOKIE_PATH = os.path.join(CACHE_PATH, 'cookiejar.txt')

# authentication key file.
AUTHKEY_FILE = os.path.join(IIVARIDIR, 'auth')

# SERVER_BASE and logging can be configured in iivarirc file.
# /etc/iivarirc is global and individual settings may be overridden
# from ~/.iivarirc
global_rc = "/etc/iivarirc"
user_rc = os.path.join(os.environ['HOME'], ".iivarirc")
rc_config = {}
def read_config(rc_file):
    # use a little bit of regexp to allow comments in json data
    s = open(rc_file, "r").read()
    s2 = re.sub(r"(?:^#|[\n\s]#).*", "", s) # strip comments
    m = re.search(r'({.*})', s2, re.DOTALL) # extract json
    return json.loads(m.group(1))
try:
    if os.path.exists(global_rc):
        rc_config = read_config(global_rc)
        print "INFO: using /etc/iivarirc"
    # override from user config
    if os.path.exists(user_rc):
        rc_config.update(read_config(user_rc))
        print "INFO: using ~/.iivarirc"
except Exception, e:
    # print and ignore errors, use defaults
    print e

# iivari server base URL
if 'SERVER_BASE' in rc_config:
    SERVER_BASE = rc_config['SERVER_BASE']
else:
    SERVER_BASE = "http://localhost:3000/conductor"

# logger level -- FATAL, WARN, INFO, DEBUG
if 'LOG_LEVEL' in rc_config:
    level = rc_config['LOG_LEVEL']
    LOG_LEVEL = logging.__dict__[level]
else:
    LOG_LEVEL = logging.DEBUG

# use fancy shell coloring in log?
if 'LOG_COLORS' in rc_config:
    colors = rc_config['LOG_COLORS']
    LOG_COLORS = (colors == "True")
else:
    LOG_COLORS = True

# use alternative log file
if 'LOG_FILE' in rc_config:
    log_file = rc_config['LOG_FILE']
    if log_file != "None":
        LOG_FILE = rc_config['LOG_FILE']
else:
    LOG_FILE = os.path.join(IIVARIDIR, 'log', 'iivari.log')

