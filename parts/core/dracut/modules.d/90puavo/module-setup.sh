#!/bin/bash

check() {
    return 0
}

depends() {
    echo "base overlay-root overlayfs"
    return 0
}

install() {
    # Todo: Remove lsof and fuser
    inst_multiple \
        /sbin/fsck \
        /sbin/fsck.ext2 \
        /sbin/fsck.ext3 \
        /sbin/fsck.ext4 \
        /sbin/blkid \
        /sbin/logsave

    inst $(which lsof)
    inst $(which fuser)

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
    inst_hook pre-udev 90 "${moddir}/hooks/init-top/puavo.sh"
    inst_hook pre-mount 90 "${moddir}/hooks/puavo-postmount/01-mount.sh"
    inst_hook pre-mount 90 "${moddir}/hooks/puavo-postmount/02-plymouth.sh"
    inst_hook cleanup 20 "${moddir}/hooks/init-bottom/puavo-nbd-server.sh"
}
