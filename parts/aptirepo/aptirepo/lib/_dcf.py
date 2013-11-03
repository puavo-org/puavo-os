# aptirepo - Simple APT Repository Tool
# Copyright (C) 2013 Tuomas Räsänen
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

import collections
import os.path

from . _error import Error

class ParseError(Error):
    """Debian control file parsing error."""
    pass

def _assert_simple(paragraph, field_name):
    if len(paragraph[field_name]) != 1:
        raise ParseError("field '%s' must be simple field" % field_name)

## TODO: add missing fields, see
## http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-debianchangesfiles
def parse_changes(filepath):
    parser = _Parser()

    paragraphs = parser(filepath)
    if len(paragraphs) != 1:
        raise ParseError("Debian changes file must consist of a single paragraph")
    paragraph = paragraphs[0]
    changes = {}

    if paragraph["Format"] != ["1.8"]:
        raise ParseError("only Debian changes file format 1.8 is supported")

    files = [s.split() for s in paragraph["Files"]]
    if files[0]:
        raise ParseError("the first line of field Files must be empty")
    changes["Files"] = files[1:]

    _assert_simple(paragraph, "Source")
    changes["Source"] = paragraph["Source"][0]

    _assert_simple(paragraph, "Distribution")
    changes["Distribution"] = paragraph["Distribution"][0]
    
    _assert_simple(paragraph, "Architecture")
    changes["Architecture"] = paragraph["Architecture"][0].split()

    return changes

def parse_distributions(confdir):
    parser = _Parser()

    paragraphs = parser(os.path.join(confdir, "distributions"))
    if len(paragraphs) < 1:
        raise ParseError("conf/distributions must consist of at least one paragraph")

    dists = {}

    for paragraph in paragraphs:
        _assert_simple(paragraph, "Architectures")
        archs = paragraph["Architectures"][0].split()

        _assert_simple(paragraph, "Components")
        comps = paragraph["Components"][0].split()

        _assert_simple(paragraph, "Pool")
        pool = paragraph["Pool"][0]

        _assert_simple(paragraph, "Codename")
        codename = paragraph["Codename"][0]
        if codename in dists:
            raise ParseError("distribution can be configured only once")

        dists[codename] = {
            "Architectures": archs,
            "Components"   : comps,
            "Pool"         : pool,
            }

    return dists

class _Parser:

    def __init__(self):
        self.paragraphs = []
        self.paragraph = collections.OrderedDict()
        self.field_name = ''
        self.field_value = []
        self.linenum = 0

    def __end_field(self):
        if self.field_name:
            if self.field_name in self.paragraph:
                raise ParseError("duplicate field name '%s' at line %d"
                                 % (self.field_name, self.linenum))
            self.paragraph[self.field_name] = self.field_value
            self.field_name = ''
            self.field_value = []

    def __end_paragraph(self):
        if self.paragraph:
            self.paragraphs.append(self.paragraph)
            self.paragraph = collections.OrderedDict()

    def __new_field(self, line):
        name, sep, value = line.partition(":")
        for char in name:
            if (33 > ord(char) > 57) or (59 > ord(char) > 126):
                raise ParseError("field name contains illegal characters", self.linenum)
        if not sep:
            raise ParseError("field separator not found", self.linenum)
        self.field_name = name
        self.field_value.append(value.strip())

    def __call__(self, filepath):
        with open(filepath) as f:
            for line in f:
                self.linenum += 1

                if not line.strip():
                    self.__end_field()
                    self.__end_paragraph()
                    continue

                if not self.field_name:
                    if line.startswith(" ") or line.startswith("\t"):
                        raise ParseError("continuation line is not allowed here", self.linenum)
                    self.__new_field(line)
                    continue

                if line.startswith(" ") or line.startswith("\t"):
                    self.field_value.append(line.strip())
                    continue

                self.__end_field()
                self.__new_field(line)

            self.__end_field()
            self.__end_paragraph()
            return self.paragraphs
