# -*- coding: utf-8 -*-
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may not
#   use this file except in compliance with the License. You may obtain a copy
#   of the License at http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.
""" crc_logger.py: Logging for multiple concurrent processes with colours.

ConcurrentRotatingColoredLogger:
* all processes share the logfile
* displays log levels in joyful colours
* autorotates when file size limit is reached

Read comments of ConcurrentRotatingColoredLogger for more information.
"""

__all__ = ['ConcurrentRotatingColoredLogger']

import logging
import os
from cloghandler import ConcurrentRotatingFileHandler

BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE = range(8)

#The background is set with 40 plus the number of the color, and the foreground with 30

#These are the sequences need to get colored ouput
RESET_SEQ = "\033[0m"
COLOR_SEQ = "\033[1;%dm"
BOLD_SEQ = "\033[1;30m" # bold black

COLORS = {
    'WARNING': YELLOW,
    'INFO': GREEN,
    'DEBUG': MAGENTA,
    'CRITICAL': YELLOW,
    'ERROR': RED
}

def formatter_message(message, use_color):
    if use_color:
        message = message.replace("$RESET", RESET_SEQ).replace("$BOLD", BOLD_SEQ)
    else:
        message = message.replace("$RESET", "").replace("$BOLD", "")
    return message

class ColoredFormatter(logging.Formatter):
    def __init__(self, msg, use_color):
        logging.Formatter.__init__(self, msg)
        self.use_color = use_color

    def format(self, record):
        levelname = record.levelname
        if self.use_color and levelname in COLORS:
            levelname_color = COLOR_SEQ % (30 + COLORS[levelname]) + levelname + RESET_SEQ
            record.levelname = levelname_color
        return logging.Formatter.format(self, record)

class ConcurrentRotatingColoredLogger(logging.Logger):
    
    LOG_COLORS = False

    DEBUG_FORMAT = "%(levelname)s  %(asctime)s $BOLD%(filename)s$RESET:%(lineno)d %(message)s"
    DEBUG_FORMAT = formatter_message(DEBUG_FORMAT, LOG_COLORS)

    INFO_FORMAT = "%(levelname)-0s  %(asctime)s $BOLD%(name)-0s$RESET:%(lineno)d %(message)s"
    INFO_FORMAT = formatter_message(INFO_FORMAT, LOG_COLORS)
    
    sizelimit = 512*1024 # set default filesize limit to 512 kB

    level = logging.INFO

    # Use an absolute path to prevent file rotation trouble.
    filename = os.path.abspath("mylogfile.log")

    @classmethod
    def debug_formatter(self):
        return ColoredFormatter(self.DEBUG_FORMAT, self.LOG_COLORS)

    @classmethod
    def info_formatter(self):
        return ColoredFormatter(self.INFO_FORMAT, self.LOG_COLORS)

    def __init__(self, name):
        logging.Logger.__init__(self, name, self.level)
        
        if self.filename is not None:
            # Rotate log after reaching sizelimit, keep 25 old copies.
            handler = ConcurrentRotatingFileHandler(
                self.filename, "a", self.sizelimit, 25)
        else:
            handler = logging.StreamHandler()

        if self.level == logging.DEBUG:
            handler.setFormatter(self.debug_formatter())
        else:
            handler.setFormatter(self.info_formatter())
        self.addHandler(handler)

