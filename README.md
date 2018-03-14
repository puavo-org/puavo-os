# Puavo OS

To setup build host, run (with sudo or as root):

    sudo make setup-buildhost

To build Puavo OS image, run:

    make rootfs-debootstrap
    make rootfs-update
    make rootfs-image

Run `make help` to get help.

## The "config"-directory

The "config"-directory contains various configurations for the image.

The file "config/rootca.pem" is a CA-certificate that will be copied to
image "/etc/puavo-image/rootca.pem" at image build time.  The default file
is compatible with the CA-infrastructure set up by Opinsys, the company
behind Puavo, BUT if you are running Puavo on your own, non-Opinsys
infrastructure, you should replace that with your own CA-certificate.

The values in "config/puavo_conf.json" override default values
for puavo-conf variables.
