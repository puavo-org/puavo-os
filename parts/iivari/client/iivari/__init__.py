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
__version__ = '1.2.2+git'
__all__ = [
    "MainWindow",
    "Display",
    "Repl"
]

import os, __builtin__
import iivari.settings

# setup log directory
log_dir = os.path.dirname(settings.LOG_FILE)
if not os.path.exists(log_dir):
    os.makedirs(log_dir)
__builtin__.LOG_FILE = settings.LOG_FILE

# setup cache directory for offline resources
if not os.path.exists(settings.CACHE_PATH):
    os.makedirs(settings.CACHE_PATH)
__builtin__.IIVARI_CACHE_PATH = settings.CACHE_PATH

import logger
from display import Display
from repl import Repl
from main import MainWindow
