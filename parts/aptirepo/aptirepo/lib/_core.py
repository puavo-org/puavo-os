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

import errno
import gzip
import hashlib
import os
import os.path
import shutil
import subprocess

from ._dcf import parse_changes
from ._dcf import parse_distributions

from ._error import Error

class ChangesError(Error):
    pass

def _gz(filepath_in):
    filepath_out = "%s.gz" % filepath_in
    with open(filepath_in, "rb") as f_in:
        with gzip.open(filepath_out, "wb") as f_out:
            f_out.writelines(f_in)

def _md5sum(filepath, block_size=4096):
    md5 = hashlib.md5()
    with open(filepath, "rb") as f:
        data = f.read(block_size)
        while data:
            md5.update(data)
            data = f.read(block_size)
    return md5.hexdigest()

class Aptirepo:
    """Class representing Aptirepo repository directory tree.

    >>> repo = Aptirepo("/srv/repo")
    >>> repo.import_changes("/var/cache/pbuilder/results/sl_3.03-17_i386.changes")
    """

    def __init__(self, rootdir, confdir=""):
        self.__rootdir = os.path.abspath(rootdir)
        self.__confdir = confdir
        if not self.__confdir:
            self.__confdir = self.__join("conf")
        self.__dists = parse_distributions(self.__confdir)
        self.__create_pool()
        self.__create_dists()

    def __create_dists(self):
        for codename, dist in self.__dists.items():
            for comp in dist["Components"]:
                for arch in dist["Architectures"]:
                    archdir = "binary-%s" % arch
                    if arch == "source":
                        archdir = "source"
                    p = self.__join("dists", codename, comp, archdir)
                    try:
                        os.makedirs(p)
                    except OSError as e:
                        if e.errno != errno.EEXIST:
                            raise e

    def __create_pool(self):
        for codename, dist in self.__dists.items():
            for comp in dist["Components"]:
                p = self.__join(dist["Pool"], comp)
                try:
                    os.makedirs(p)
                except OSError  as e:
                    if e.errno != errno.EEXIST:
                        raise e

    def __join(self, *args):
        return os.path.join(self.__rootdir, *args)

    def __write_contents(self, pool, codename, comp):
        path = self.__join("dists", codename, comp, "Contents.gz")
        with gzip.open(path, 'wb') as f:
            subprocess.check_call(["apt-ftparchive", "--db", "db",
                                   "contents", os.path.join(pool, comp)],
                                  stdout=f, cwd=self.__rootdir)

    def __write_packages(self, pool, codename, comp, arch):
        path = self.__join("dists", codename, comp, "binary-%s" % arch,
                           "Packages")
        with open(path, "w") as f:
            subprocess.check_call(["apt-ftparchive", "--db", "db",
                                   "packages", os.path.join(pool, comp)],
                                  stdout=f, cwd=self.__rootdir)
        _gz(path)

    def __write_release(self, codename, comps, archs):
        with open(self.__join("dists", codename, "Release"), "w") as f:
            subprocess.check_call(["apt-ftparchive", "--db", "db",
                                   "-o", "APT::FTPArchive::Release::Codename=%s" % codename,
                                   "-o", "APT::FTPArchive::Release::Components=%s" % " ".join(comps),
                                   "-o", "APT::FTPArchive::Release::Architectures=%s" % " ".join(archs),
                                   "release", os.path.join("dists", codename)],
                                  stdout=f, cwd=self.__rootdir)

    def __write_sources(self, pool, codename, comp):
        path = self.__join("dists", codename, comp, "source", "Sources")
        with open(path, "w") as f:
            subprocess.check_call(["apt-ftparchive",
                                   "sources", os.path.join(pool, comp)],
                                  stdout=f, cwd=self.__rootdir)
        _gz(path)

    def import_changes(self, changes_filepath):
        changes = parse_changes(changes_filepath)
        codename = changes["Distribution"]
        source_name = changes["Source"]
        dist = self.__dists[codename]
        changes_dirpath = os.path.dirname(changes_filepath)
        for md5, size, section, priority, filename in changes["Files"]:
            filepath = os.path.join(changes_dirpath, filename)
            real_md5 = _md5sum(filepath)

            if md5 != real_md5:
                raise ChangesError("md5 checksum mismatch '%s': '%s' != '%s'" % (filename, md5, real_md5))

            component, sep, section = section.partition("/")
            if not sep:
                component="main"

            abbrevdir = self.__join(dist["Pool"], component, source_name[0])
            try:
                os.mkdir(abbrevdir)
            except OSError as e:
                if e.errno != errno.EEXIST:
                    raise e

            packagedir = os.path.join(abbrevdir, source_name)
            try:
                os.mkdir(packagedir)
            except OSError as e:
                if e.errno != errno.EEXIST:
                    raise e

            dest_filepath = os.path.join(packagedir, filename)
            if os.path.exists(dest_filepath):
                if _md5sum(dest_filepath) != md5:
                    raise ChnagesError("'%s' already exists in the repository with different checksum" % filename)
                continue

            shutil.copyfile(filepath, dest_filepath)

    def update_dists(self):
        for codename, dist in self.__dists.items():
            pool = dist["Pool"]
            comps = dist["Components"]
            archs = dist["Architectures"]
            for comp in comps:
                self.__write_contents(pool, codename, comp)
                for arch in archs:
                    if arch == "source":
                        self.__write_sources(pool, codename, comp)
                    else:
                        self.__write_packages(pool, codename, comp, arch)
            self.__write_release(codename, comps, archs)
