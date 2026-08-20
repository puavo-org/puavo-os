# Puavo OS

To build images with these sources,
your build environment should be a Debian GNU/Linux
installation.  To build images with "Bullseye"-version,
use the "bullseye"-branch.  To build images with "Bookworm"-version,
use the "bookworm"-branch.  The build host should probably be
of the same version your target image is.  As of May 2024,
our main production version is Bullseye and Bookworm
is under active development.

After cloning the repository, you should also update
submodules (unless the repository was cloned with parameter --recursive):

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
fresh Debian Bookworm virtual machine works with the steps listed
above. Due to build process using a ramdisk /tmp, the virtual
machine should have at least 16 GB of RAM for successful build.

## Container build

Images can also be built inside an OCI container, which avoids having to
set up a dedicated Debian build host.  This is the recommended way to
build on Apple hardware with e.g. Docker Desktop (which uses BuildKit by
default) or Podman.  Clone with `--recursive` (or run
`git submodule update --init --recursive`) first, then:

    CONTAINER=docker ./scripts/build.sh

The script builds the `puavo-os-builder` image and starts the build in the
background.  Follow the build with Docker:

    docker logs -f "$(docker ps -lq)"

or with Apple's `container` tool:

    container logs -f "$(container list -q)"

Run the build in the foreground with `FOREGROUND=1` instead.

The workspace (this repository) is bind-mounted into the container and the
build directories and images live in the `puavo-os-build` and
`puavo-os-output` volumes.  Built images can be copied out of the output
volume with:

    docker run --rm --volume puavo-os-output:/output         --volume "$PWD/images":/copy         debian:trixie-slim cp -a /output/. /copy/

By default the build targets amd64 images.  On Apple Silicon machines
Docker Desktop and Apple's `container` tool run the amd64 container
through Rosetta 2, which must be enabled.  Override the platform or
architecture with `PLATFORM` and `TARGET_ARCH` if desired.

UKI PCR signing (`ukify --measure`) needs `systemd-measure` plus the
`libtss2-*` libraries that systemd only Suggests.  Private keys are
chmod'd to 0600 before signing because `rootfs-sync-repo` otherwise
leaves them group-writable.  `verify-boot-components` needs `python3-pydantic`.

Build-time variables:

- `CONTAINER`: container tool (`docker`, `podman`, `container`)
- `CONTAINER_CPUS` / `CONTAINER_MEMORY`: resources for the build
  (default 8 CPUs / 16G)
- `PLATFORM`: platform for the builder image (default `linux/amd64`)
- `IMAGE_CLASSES`: comma-separated image classes (default `allinone`)
- `TARGETS`: make targets to run
  (default `rootfs-debootstrap rootfs-update rootfs-image`)
- `TARGET_ARCH`: target architecture (default `amd64`)
- `RELEASE_NAME`: image release name (default derived from git)
- `REUSE_ROOTFS=1`: skip `rootfs-debootstrap` when the rootfs exists
- `DEBOOTSTRAP_MIRROR`: override the debootstrap mirror
- `FOREGROUND=1`: run the build container attached with `--rm`
- `OUTPUT_DIR`: directory inside the container for built images
  (default `/output`, the `puavo-os-output` volume)

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
