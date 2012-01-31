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

# log file location. leave undefined for console output.
LOG_FILE = os.path.join(IIVARIDIR, 'log', 'iivari.log')

# Rest of the settings may be configured from iivarirc file.
# The iivarirc is json configuration file placed to 
# either ~/.iivarirc or /etc/iivarirc.
primary_rc = os.path.join(os.environ['HOME'], ".iivarirc")
secondary_rc = "/etc/iivarirc"
#secondary_rc = "iivarirc" # DEBUG
rc_config = {}
try:
	rc_file = None
	if os.path.exists(primary_rc):
		rc_file = primary_rc
	elif os.path.exists(secondary_rc):
		rc_file = secondary_rc
	else:
		print "WARNING: ~/.iivarirc nor /etc/iivarirc was not found, using defaults"

	if rc_file:
		# use a little bit of regexp to allow comments in json data
		s = open(rc_file, "r").read()
		s2 = re.sub(r"(?:^#|[\n\s]#).*", "", s) # strip comments
		m = re.search(r'({.*})', s2, re.DOTALL) # extract json
		rc_config = json.loads(m.group(1))
except Exception, e:
	print e

# iivari server base URL
if 'SERVER_BASE' in rc_config:
	SERVER_BASE = rc_config['SERVER_BASE']
else:
	SERVER_BASE = "http://localhost:3000"

# logger level -- FATAL, WARN, INFO, DEBUG
if 'LOG_LEVEL' in rc_config:
	level = rc_config['LOG_LEVEL']
	LOG_LEVEL = logging.__dict__[level]
else:
	LOG_LEVEL = logging.DEBUG

# use fancy shell coloring in log?
if 'LOG_COLORS' in rc_config:
	colors = rc_config['LOG_COLORS']
	if colors == "False":
		LOG_COLORS = False
	else:
		LOG_COLORS = True
else:
	LOG_COLORS = True
