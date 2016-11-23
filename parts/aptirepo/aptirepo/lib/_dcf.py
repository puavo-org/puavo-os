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
Parse Debian control files

http://www.debian.org/doc/debian-policy/ch-controlfields.html
"""

import os.path

import debian.deb822

from . _error import Error

class ParseError(Error):
    """Debian control file parsing error."""
    pass

def parse_simple_list(paragraph, name, default=None):
    try:
        value = paragraph[name]
    except KeyError:
        if default is None:
            raise ParseError("mandatory field '%s' is missing" % name)
        value = default
    lines = value.splitlines()
    if not lines:
        raise ParseError("field '%s' must not be empty" % name)
    if len(lines) != 1:
        raise ParseError("field '%s' must be simple field" % name)
    return lines[0].split()

def parse_distributions(confdir):
    dists = {}
    filepath = os.path.join(confdir, "distributions")
    with open(filepath) as f:
        paragraph = debian.deb822.Deb822(f)
        while paragraph:
            codename = parse_simple_list(paragraph, "Codename")[0]
            archs = parse_simple_list(paragraph, "Architectures")
            comps = parse_simple_list(paragraph, "Components")
            pool = parse_simple_list(paragraph, "Pool", "pool")[0]

            if codename in dists:
                raise ParseError("duplicate distribution '%s'" % codename)

            dists[codename] = {
                "Architectures": archs,
                "Components": comps,
                "Pool": pool
                }

            paragraph = debian.deb822.Deb822(f)

    if not dists:
        raise ParseError("empty distributions")

    return dists
