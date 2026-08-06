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
                  /usr/bin/tpm2_dictionarylockout \
                  /usr/lib/systemd/systemd-pcrlock \
                  /usr/sbin/cryptsetup         \
                  /usr/sbin/puavo-boot-trust-manager \
                  /usr/bin/efi-updatevar \
                  /usr/bin/sign-efi-sig-list \
                  /usr/bin/chattr \
                  /usr/bin/openssl

    # Install Secure Boot update scripts
    inst "${moddir}/scripts/update-secure-boot-db" \
         "/usr/sbin/update-secure-boot-db"
    inst "${moddir}/scripts/update-secure-boot-dbx" \
         "/usr/sbin/update-secure-boot-dbx"

    # Install the service file
    inst "${moddir}/puavo-boot-trust-manager.service" \
         "/usr/lib/systemd/system/puavo-boot-trust-manager.service"

    # Install the service start script
    inst "${moddir}/start-boot-trust-manager" \
        "/usr/sbin/start-boot-trust-manager"

    # Install persistent configurators
    mkdir -p "${initdir}/etc/puavo"
    "${moddir}/scripts/install-persistent-configurators" "${initdir}/etc/puavo/"

    # Install kernel command-line signer and related utilities
    instmods puavo_command_line_signer
    inst "${moddir}/scripts/initialize-command-line-signer" \
         "/usr/sbin/puavo-command-line-signer-initialize"
    inst_multiple /usr/sbin/puavo-command-line-sign

    # Install all public TPM PCR keys and the server
    # signing public key (if present)
    mkdir -p "${initdir}/etc/puavo-conf"
    cp /etc/puavo-conf/tpm2-pcr-public-key*.pem \
       "${initdir}/etc/puavo-conf" || true
    cp /etc/puavo-conf/server.pub \
       "${initdir}/etc/puavo-conf" || true

    # Enable the service in initrd
    mkdir -p "${initdir}/etc/systemd/system/initrd.target.wants"
    ln_r "/usr/lib/systemd/system/puavo-boot-trust-manager.service" \
         "/etc/systemd/system/initrd.target.wants/puavo-boot-trust-manager.service"
}
