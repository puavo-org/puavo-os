#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (C) 2015 Opinsys Oy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

from distutils.core import setup
import os.path

setup(name='puavowlanmapper',
      version='0.1',
      description='Simple APT Repository Tool.',
      author='Tuomas Räsänen',
      author_email='tuomasjjrasanen@tjjr.fi',
      url='http://github.com/opinsys/puavo-wlan',
      scripts=['puavo-wlanmapper'],
      packages=['puavowlanmapper'],
      license='GPLv2+',
      platforms=['Linux'],
      classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: X11 Applications :: Qt",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: GNU General Public License (GPL)",
        "Operating System :: POSIX :: Linux",
        "Topic :: System :: Networking :: Monitoring",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.4",
        ],
      requires=['matplotlib', 'numpy', 'scipy'],
      provides=['puavowlanmapper'],
  )