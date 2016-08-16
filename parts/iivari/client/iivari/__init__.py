# -*- coding: utf-8 -*-
"""
Copyright © 2011, 2012 Opinsys Oy

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
__version__ = '1.3.4'
__all__ = [
    "MainWindow",
    "Display",
    "Repl"
]

import os, __builtin__
import iivari.settings

if 'LOG_FILE' in settings.__dict__:
    # setup log directory
    log_file = settings.LOG_FILE
    if log_file is not None:
        log_dir = os.path.dirname(log_file)
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
    __builtin__.LOG_FILE = log_file
else:
    # when LOG_FILE is undefined, log to console
    __builtin__.LOG_FILE = None

if 'CACHE_PATH' in settings.__dict__:
    # setup cache directory for offline resources
    cache_path = settings.CACHE_PATH
    if cache_path is not None:
        if not os.path.exists(cache_path):
            os.makedirs(cache_path)
    __builtin__.IIVARI_CACHE_PATH = cache_path
else:
    __builtin__.IIVARI_CACHE_PATH = None

import logger
from display import Display
from repl import Repl
from main import MainWindow
