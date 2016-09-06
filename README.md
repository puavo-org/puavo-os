# Puavo OS

To install build tools on Debian Jessie, run:

    sudo ./install-build-tools

To build Puavo OS image, run:

    make rootfs-debootstrap
    make rootfs-update
    make rootfs-image

Run `make help` to get help.
