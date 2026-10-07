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
                  /usr/bin/loadkeys \
                  /usr/bin/openssl

    # Install the command-line manager's key load and what it runs
    inst_multiple /usr/lib/puavo-core/puavo-command-line-manager-load \
                  /usr/bin/tpm2 \
                  awk \
                  install \
                  mktemp

    # TODO(command-line-server-key): Once Puppet configures the server
    # key, remove these lines, the wants link below, the placeholder keys
    # unit and its script.
    inst /usr/lib/puavo-core/puavo-command-line-manager-placeholder-keys
    inst "${moddir}/puavo-command-line-manager-placeholder-keys.service" \
         "/usr/lib/systemd/system/puavo-command-line-manager-placeholder-keys.service"

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

    # Prebuild keymaps to avoid ckbcomp and its "large" dependencies in initrd.
    keymap_directory="${initdir}/usr/share/puavo/keymaps"
    mkdir -p "$keymap_directory"

    while read -r keymap; do
        ckbcomp "$keymap" | gzip -9 > "${keymap_directory}/${keymap}.kmap.gz"
    done < "${moddir}/keymaps"

    # Install all public TPM PCR keys and the server
    # signing public key (if present)
    mkdir -p "${initdir}/etc/puavo-conf"
    cp /etc/puavo-conf/tpm2-pcr-public-key*.pem \
       "${initdir}/etc/puavo-conf" || true
    cp /etc/puavo-conf/server.pub \
       "${initdir}/etc/puavo-conf" || true

    # An enrollment policy may reference a certificate file of the database
    mkdir -p "${initdir}/etc/puavo-secure-boot/db"
    cp /etc/puavo-secure-boot/db/*.der \
       "${initdir}/etc/puavo-secure-boot/db" || true

    # The database of the image and its build date, for enrollment
    cp /etc/puavo-secure-boot/db.esl \
       /etc/puavo-secure-boot/built \
       "${initdir}/etc/puavo-secure-boot" || true
    cp /etc/puavo-secure-boot/dbx.bin \
       "${initdir}/etc/puavo-secure-boot" 2>/dev/null || true

    # Enable the service in initrd
    mkdir -p "${initdir}/etc/systemd/system/initrd.target.wants"
    ln_r "/usr/lib/systemd/system/puavo-boot-trust-manager.service" \
         "/etc/systemd/system/initrd.target.wants/puavo-boot-trust-manager.service"
    ln_r "/usr/lib/systemd/system/puavo-command-line-manager-placeholder-keys.service" \
         "/etc/systemd/system/initrd.target.wants/puavo-command-line-manager-placeholder-keys.service"
}
