#!/bin/bash

check() {
    return 0
}

depends() {
    echo "base crypt dm nbd overlay-root overlayfs systemd systemd-cryptsetup tpm2-tss"
    return 0
}

install() {
    inst_multiple /sbin/blkid     \
                  /sbin/fsck      \
                  /sbin/fsck.ext2 \
                  /sbin/fsck.ext3 \
                  /sbin/fsck.ext4 \
                  /sbin/logsave   \
                  /usr/bin/pv     \
                  /usr/sbin/lvm   \
                  $(which lsblk)  \
                  $(which blkid)  \
                  $(which xxd)    \
                  $(which find)   \
                  $(which awk)    \
                  $(which cut)

    inst "$moddir/puavo-current-efi-boot-disk" /usr/bin/puavo-current-efi-boot-disk

    # Remove NVIDIA blacklist and configuration files
    rm -f "${initdir}/etc/modprobe.d/nvidia-blacklists-nouveau.conf" \
          "${initdir}/etc/modprobe.d/nvidia.conf"                    \
          "${initdir}/etc/modprobe.d/nvidia-kernel-common.conf"

    # Copy NVIDIA configuration if it exists
    if [ -d /etc/nvidia ]; then
        inst_dir /etc/nvidia
        cp -LR /etc/nvidia/* "${initdir}/etc/nvidia/"
    fi

    # Install hooks
    inst_hook pre-udev  90 "${moddir}/puavo-kernel-module-setup.sh"
    inst_hook pre-pivot 90 "${moddir}/puavo-rootmount.sh"
    inst_hook pre-pivot 91 "${moddir}/puavo-plymouth.sh"
    inst_hook cleanup   20 "${moddir}/puavo-nbd-server.sh"
}
