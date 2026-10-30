#!/bin/bash

# Included only when another module depends on it.
check() {
    return 255
}

install() {
    # GNU timeout, because busybox exits with another status on a timeout.
    inst_multiple /usr/lib/puavo-ltsp-install/puavo-collect-boot-diagnostics \
                  /usr/lib/puavo-ltsp-install/puavo-manage-boot-diagnostics \
                  /usr/lib/systemd/systemd-pcrlock \
                  /usr/bin/efibootmgr \
                  /usr/bin/jq \
                  /usr/bin/journalctl \
                  /usr/bin/lsblk \
                  /usr/bin/timeout \
                  /usr/bin/tpm2 \
                  /usr/sbin/cryptsetup \
                  /usr/sbin/slab-info
}
