# Puavo packages

This repository contains a package management tool, ``puavo-pkg``, and
package installer sources under ``packages/``.



## Installation

The package manager tool is a simple standalone Bash script which does
not necessarily need to be installed anywhere. However, ``Makefile`` is
provided to make installation a breeze:

To install it to ``/usr/sbin``, run:

    make install

To build a ``.deb`` package and install it, run:

    make deb
    sudo dpkg -i ../puavo-pkg_0.1.3_all.deb

## Usage

To install a package with an installer file, run:

    puavo-pkg install PACKAGE.tar.gz

To list all installed packages, run:

    puavo-pkg list

To remove an installed package, run:

    puavo-pkg remove PACKAGE

To reconfigure an installed package, run:

    puavo-pkg reconfigure PACKAGE

For usage details, run:

    puavo-pkg --help


## Configuration

The default configuration can be changed by providing
`/etc/puavo-pkg/config`. The following configuration options are recognized:

- ``PUAVO_PKG_ROOTDIR``: The root directory of the package
  tree. Defaults to ``/var/lib/puavo-pkg``.


- ``PUAVO_PKG_CACHEDIR``: Cache directory used for storing downloaded
  upstream packs etc. Defaults to ``/var/cache/puavo-pkg``.


## Packaging

This section describes the package format of version 1.

### Installer files

Currently, ``puavo-pkg`` supports package installations only with
installer files. Installer files are gzipped tar archives which **must** be
named as ``PACKAGE.tar.gz`` where ``PACKAGE`` is the name of the package
the installed by the installer file. All paths inside the archive **must**
be prefixed by ``PACKAGE/``.

Mandatory files:

- ``PACKAGE/rules``

Optional files:

- ``PACKAGE/description``
- ``PACKAGE/format``
- ``PACKAGE/legend``
- ``PACKAGE/license``
- ``PACKAGE/upstream_pack_url``
- ``PACKAGE/upstream_pack_md5sum``

An example installer archive layout for ``mypackage`` package might look
like this:

    $ tar -tf mypackage.tar.gz
    mypackage/description
    mypackage/format
    mypackage/legend
    mypackage/license
    mypackage/rules
    mypackage/upstream_pack_url
    mypackage/upstream_pack_md5sum


#### ``PACKAGE/rules``

The installer archive **must** contain an executable ``PACKAGE/rules``
file, which **must** accept one or more command line
arguments. ``PACKAGE/rules`` will be executed by ``puavo-pkg`` which
will pass an installer command (``download``, ``unpack``, ``configure``
and ``unconfigure``) as the first argument.

On success, ``PACKAGE/rules`` must exit with status code 0. If
``download`` command fails because of a network failure,
``PACKAGE/rules`` must exit with status code 2. Otherwise,
``PACKAGE/rules`` must exit with status code 1.

#### ``PACKAGE/description``

Optionally, the installer archive **can** contain
``PACKAGE/description`` file which must contain one or more lines long
description of the package.


#### ``PACKAGE/legend``

Optionally, the installer archive **can** contain ``PACKAGE/legend``
file which must contain a short human readable name for the package.


#### ``PACKAGE/format``

Optionally, the installer archive **can** contain ``PACKAGE/format``
file which must contain the version number of the package format. If the
``PACKAGE/format`` does not exist, the version of the package format is
assumed to be 1.


#### ``PACKAGE/license``

Optionally, the installer archive **can** contain ``PACKAGE/license``
file which must contain End User License Agreement or Terms of Service
of the package. The format of the file can be anything, however a
browser readable format (``text/plain``, ``text/html`` or
``application/pdf``) is recommended, because ``puavo-pkg`` command
``license`` can be used to print a file URL pointing the license file.


#### ``PACKAGE/upstream_pack_url``

Optionally, the installer archive **can** contain
``PACKAGE/upstream_pack_url`` file which **must** contain a valid URL
pointing to the upstream package. If the file exists, ``puavo-pkg``
downloads the file pointed by the URL with a built-in download
function. If the file does *not* exists, ``PACKAGE/rules`` must take
care of downloading when ``download`` is passed to it as an installer
command.


#### ``PACKAGE/upstream_pack_md5sum``

Optionally, the installer archive **can** contain
``PACKAGE/upstream_pack_md5sum`` file which **must** contain the MD5
checksum of the upstream package. If the file exists, ``puavo-pkg``
verifies the downloaded upstream package by comparing the MD5 checksum
of the upstream package with the one given in this file. The checksum is
also used as a cache identifier. If this file does not exists, caching
of the package is disabled.
