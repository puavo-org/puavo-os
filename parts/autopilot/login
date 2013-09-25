#!/bin/sh
# puavo-autopilot - automatic test tool for Puavo desktop sessions
# Copyright (C) 2013 Opinsys Oy
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

set -eu

if [ $# -ne 2 ]; then
    echo "E: wrong number of arguments" >&2
    echo "Usage: $0 USERNAME PASSWORD" >&2
    exit 1
fi

username=$1
password=$2

switch-to-login-vt

## The "Guest Session" widget might be the active one, click up arrow to
## activate the normal login widget.
xte 'key Up'
sleep 1

## The login widget might be dirty, click esc to clear it.
xte 'key Escape'
sleep 1

xte "str ${username}"
xte 'key Return'
sleep 2 ## Password widget activates slowly.

xte "str ${password}"
xte 'key Return'
