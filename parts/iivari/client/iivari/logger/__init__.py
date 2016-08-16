# -*- coding: utf-8 -*-
"""Initializes a rotating, colored logger.

Rotates at given file size limit.
"""
import os
import __builtin__
from logging import setLoggerClass
from crc_logger import ConcurrentRotatingColoredLogger
from iivari import settings

LOG_FILE = None # console output
try:
    # the settings are read in main script
    LOG_FILE = __builtin__.LOG_FILE
except AttributeError:
    pass
# if LOG_FILE is not None:
#     print "Logging to %s" % LOG_FILE

ConcurrentRotatingColoredLogger.filename = LOG_FILE

# set logger level
ConcurrentRotatingColoredLogger.level = settings.LOG_LEVEL

# use colors in log?
ConcurrentRotatingColoredLogger.LOG_COLORS = settings.LOG_COLORS

# set filesize limit for rotation
ConcurrentRotatingColoredLogger.sizelimit = 2*1024*1024 # 2 MiB

# call logging.setLoggerClass to register logger
setLoggerClass(ConcurrentRotatingColoredLogger)
