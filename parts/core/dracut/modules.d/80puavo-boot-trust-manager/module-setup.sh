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

    # Install persistent configurators
    mkdir -p "${initdir}/etc/puavo"
    "${moddir}/scripts/install-persistent-configurators" "${initdir}/etc/puavo/"

    # Install all public TPM PCR keys
    mkdir -p "${initdir}/etc/puavo-conf"
    cp /etc/puavo-conf/tpm2-pcr-public-key*.pem \
       "${initdir}/etc/puavo-conf" || true

    # Enable the service in initrd
    mkdir -p "${initdir}/etc/systemd/system/initrd.target.wants"
    ln_r "/usr/lib/systemd/system/puavo-boot-trust-manager.service" \
         "/etc/systemd/system/initrd.target.wants/puavo-boot-trust-manager.service"
}
