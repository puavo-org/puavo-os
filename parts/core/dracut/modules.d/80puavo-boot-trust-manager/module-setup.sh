#!/bin/bash

check() {
    return 0
}

depends() {
    echo "base crypt dm systemd systemd-cryptsetup tpm2-tss"
    return 0
}

install() {
    inst_multiple /usr/bin/systemd-cryptenroll \
                  /usr/sbin/cryptsetup         \
                  /usr/sbin/puavo-boot-trust-manager

    # Install the service file
    inst "${moddir}/puavo-boot-trust-manager.service" \
         "/usr/lib/systemd/system/puavo-boot-trust-manager.service"

    # Enable the service in initrd
    mkdir -p "${initdir}/etc/systemd/system/initrd.target.wants"
    ln_r "/usr/lib/systemd/system/puavo-boot-trust-manager.service" \
         "/etc/systemd/system/initrd.target.wants/puavo-boot-trust-manager.service"
}
