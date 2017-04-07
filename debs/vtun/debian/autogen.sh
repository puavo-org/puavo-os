#!/bin/sh
# autotools update script, patching first configure.in. Based on
# /usr/share/doc/autotools-dev/examples
#
# Requires: automake 1.9, autoconf 2.57+
# Conflicts: autoconf 2.13
set -e

# Refresh GNU autotools toolchain.
echo Cleaning autotools files...
find -type d -name autom4te.cache -print0 | xargs -0 rm -rf \;
find -type f \( -name missing -o -name install-sh -o -name mkinstalldirs \
	-o -name depcomp -o -name ltmain.sh -o -name configure \
	-o -name config.sub -o -name config.guess \) -print0 | xargs -0 rm -f

cp -f /usr/share/automake/install-sh .
cp -f /usr/share/misc/config.sub .
cp -f /usr/share/misc/config.guess .

patch -p0 < debian/configure.in.patch

echo Running autoreconf...
autoreconf --force --install

find -type d -name autom4te.cache -print0 | xargs -0 rm -rf \;
rm -f config.h.in~
