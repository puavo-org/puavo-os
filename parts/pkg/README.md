# Puavo packages

This repository contains a package management tool, ``puavo-pkg``, and
package installer sources under ``packages/``.



## Installation

The package manager tool is a simple standalone Bash script which does
not necessarily need to be installed anywhere. However, ``Makefile`` is
provided to make installation a breeze:

To install it to ``/usr/local/sbin``, run:

    make install

Or to install it to ``/usr/sbin``, run:

    make install prefix=/usr



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



## Packaging

### Installer files

Currently, ``puavo-pkg`` supports package installations only with
installer files. Installer files are gzipped tar archives which must be
named as ``PACKAGE.tar.gz`` where ``PACKAGE`` is the name of the package
the installed by the installer file. All paths inside the archive must
be prefixed by ``PACKAGE/``.

The installer file must have an executable ``PACKAGE/rules`` file, which
must accept one or more command line arguments. ``PACKAGE/rules`` will
be executed by ``puavo-pkg`` which will pass an installer command as the
first argument. There are four installer commands: ``download``,
``unpack``, ``configure`` and ``unconfigure``.

Optionally, the installer file can have ``PACKAGE/upstream.pack.url``
and ``PACKAGE/upstream.pack.md5sum`` files. The former must contain a
valid URL pointing to the upstream package and the latter must contain
the MD5 checksum of the upstream package.

An example installer file layout for ``mypackage`` package could look
like this:

    $ tar -tf mypackage.tar.gz
    mypackage/rules
    mypackage/upstream.pack.url
    mypackage/upstream.pack.md5sum

TBC