# Opinsys OS

To setup build host, run (with sudo or as root):

    sudo make setup-buildhost

To build Puavo OS image, run:

    make rootfs-debootstrap
    make rootfs-update
    make rootfs-image

Run `make help` to get help.

## Copyright

Almost all files here are copyright (C) Opinsys Oy.  They are licensed
under GPLv2+, that is, either version 2 of the GPL License, or (at your
option) any later version.

The exceptions to that are most files under rules/gnome_shell_extensions,
which are subject to copyright and license terms specified on the extension
files themselves.  Also, the "jetpipe"-script is taken from The LTSP Project
files, and is copyright by Canonical Ltd. (likewise GPLv2+).

## Notes on distribution rights (to Opinsys)

### Ekapeli-alku

On 21.5.2015, Ville Mönkkönen, on a private email said:

> Voitte toki jaella peliä edelleen käyttäjille, kunhan ette erikseen
> pyydä käyttäjiltä rahaa pelin jakelusta.
