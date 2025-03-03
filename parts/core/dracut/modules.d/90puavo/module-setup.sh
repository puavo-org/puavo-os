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
        /sbin/logsave \
        /usr/bin/lspci \
        /usr/bin/lsusb \
        /usr/bin/puavo-conf \
        /usr/sbin/dmidecode \
        /usr/sbin/puavo-conf-update

    inst $(which lsof)
    inst $(which fuser)

    # Install Puavo specific files
    inst_dir /etc/puavo-conf \
             /usr/bin        \
             /usr/sbin       \
             /usr/share

    inst /etc/puavo-conf/image.json /etc/puavo-conf/image.json

    inst_dir /usr/share/puavo-conf
    cp -a /usr/share/puavo-conf "${initdir}/usr/share/"

    inst_dir /usr/lib
    ln -s libpuavoconf.so.0 "${initdir}/usr/lib/libpuavoconf.so"

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
    # Todo: Remove once unnecessary
    inst_hook cleanup 20 "${moddir}/hooks/init-bottom/puavo-conf-update-insertion.sh"
}
