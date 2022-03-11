# Puavo OS

To build images with these sources,
your build environment should be a Debian GNU/Linux
installation.  To build images with "Buster"-version,
use the "buster"-branch.  To build images with "Bullseye"-version,
use the "bullseye"-branch.  The build host should probably be
of the same version your target image is.  As of March 2022,
our main production version is Buster and Bullseye
is under active development.

After cloning the repository, you should also update
submodules:

    git submodule init
    git submodule update

To setup build host, run (with sudo or as root):

    sudo make setup-buildhost

To build Puavo OS image, run:

    make rootfs-debootstrap
    make rootfs-update
    make rootfs-image

After successful build, the built image can be found by
default from /srv/puavo-os-images

Run `make help` to get help.

Note: As the build process scouts some parameters from the runtime
environment, building it under a puavo-os session might require
some manual steps not yet documented here. Building in e.g. a
fresh Debian Bullseye virtual machine works with the steps listed
above. Due to build process using a ramdisk /tmp, the virtual
machine should have at least 16 GB of RAM for successful build.

## Using Puavo OS images

Puavo OS image is not very useful in itself.
Puavo OS is designed to be used with a Puavo Web
server, that is used to manage user accounts
and devices.

A Puavo OS image can be used to boot a system with PXE
in case a suitably configured network boot server
is available.  To install a host with a removable drive,
a separate _installation image_ is required.
You can try using ``puavo-make-install-disk`` to create
one, or simply check out https://puavo.org for
some example installation images.

An installation image can be booted in "live"-mode
to test hardware compatibility with Puavo OS.
When booted in "normal" boot mode, an installation
should be performed.  To install, a login to
a Puavo Server is required to make it possible to
manage the host.  In case a Puavo Server is not
available, the instructions in
https://github.com/puavo-org/puavo-standalone
can be followed to setup a test server.
Do not use the test server in production before
understanding how it works and setting up
passwords properly.

## The "config"-directory

The "config"-directory contains various configurations for the image.

The file "config/rootca.pem" is a CA-certificate that will be copied to
image "/etc/puavo-image/rootca.pem" at image build time.  The default file
is compatible with the CA-infrastructure set up by Opinsys, the company
behind Puavo, BUT if you are running Puavo on your own, non-Opinsys
infrastructure, you should replace that with your own CA-certificate.

The values in "config/puavo_conf.json" override default values
for puavo-conf variables.

## Copyright

Almost all files here are copyright (C) Opinsys Oy.  They are licensed
under GPLv2+, that is, either version 2 of the GPL License, or (at your
option) any later version.

The exceptions to that are most files under rules/gnome_shell_extensions,
which are subject to copyright and license terms specified on the extension
files themselves.  Also, the "jetpipe"-script is taken from The LTSP Project
files, and is copyright by Canonical Ltd. (likewise GPLv2+).  The SSL
libraries in rules/primus/files are from the OpenSSL Project and are under
Apache License Version 2.0.
