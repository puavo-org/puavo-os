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
__version__ = '1.2.0'
__all__ = [
    "MainWindow",
    "Display",
    "Repl"
]

import os, __builtin__
import iivari.settings

# base log and cache default root to repository main directory
HOME = os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))

# decide which log file to use and setup the log directory
try:
    # settings overrides
    log_file = settings.LOG_FILE
    log_dir = os.path.dirname(log_file)
except AttributeError:
    log_dir = os.path.join(HOME,'log')
    log_file = os.path.join(log_dir, 'iivari-infotv.log')
if log_dir and not os.path.exists(log_dir):
    os.makedirs(log_dir)
__builtin__.LOG_FILE = log_file

# setup cache directory for offline resources
try:
    cache_path = settings.CACHE_PATH
except AttributeError:
    cache_path = os.path.join(HOME,'cache')
if not os.path.exists(cache_path):
    os.makedirs(cache_path)
__builtin__.IIVARI_CACHE_PATH = cache_path

import logger
from display import Display
from repl import Repl
from main import MainWindow


