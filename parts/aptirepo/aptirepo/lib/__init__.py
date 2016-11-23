# aptirepo - Simple APT Repository Tool
# Copyright (C) 2013,2014 Opinsys
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

"""
Simple APT Repository Tool

Author: Tuomas Räsänen <tuomasjjrasanen@tjjr.fi>

>>> repo = aptirepo.Aptirepo("/srv/repo")
>>> repo.import_changes("/var/cache/pbuilder/results/sl_3.03-17_i386.changes")
>>> repo.update_dists()

"""

from ._core import Aptirepo

__all__ = ["Aptirepo"]
