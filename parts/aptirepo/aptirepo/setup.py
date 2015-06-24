# -*- coding: utf-8 -*-
# aptirepo - Simple APT Repository Tool
# Copyright (C) 2013,2014,2015 Opinsys
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

from distutils.core import setup
import os.path

import subprocess

version = subprocess.check_output(
    ['dpkg-parsechangelog', '-SVersion', '-l../debian/changelog']).strip()

setup(name='aptirepo',
      version=version,
      description='Simple APT Repository Tool.',
      author='Tuomas Räsänen',
      author_email='tuomasjjrasanen@tjjr.fi',
      url='http://github.com/opinsys/aptirepo',
      scripts=['aptirepo', 'aptirepo-updatedistsd'],
      package_dir={'aptirepo': 'lib'},
      packages=['aptirepo'],
      license='GPLv2+',
      platforms=['Linux'],
      classifiers=[
        "Development Status :: 1 - Planning",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: GNU General Public License (GPL)",
        "Operating System :: POSIX :: Linux",
        "Topic :: System :: Archiving :: Packaging",
        "Programming Language :: Python :: 2",
        "Programming Language :: Python :: 2.7",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.1",
        "Programming Language :: Python :: 3.2",
        ],
      requires=['debian'],
      provides=['aptirepo'],
      )
