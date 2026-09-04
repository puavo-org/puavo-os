#!/bin/bash

check() {
  return 0
}

depends() {
  echo "base crypt dm nbd overlay-root overlayfs systemd systemd-cryptsetup tpm2-tss"
  return 0
}

install() {
  inst_multiple /sbin/blkid \
    /sbin/fsck \
    /sbin/fsck.ext2 \
    /sbin/fsck.ext3 \
    /sbin/fsck.ext4 \
    /sbin/logsave \
    /usr/bin/pv \
    /usr/sbin/lvm \
    $(which lsblk) \
    $(which blkid) \
    $(which xxd) \
    $(which find) \
    $(which awk) \
    $(which cut) \
    $(which base64) \
    $(which jq) \
    $(which losetup) \
    $(which tail) \
    $(which veritysetup)

  # The root filesystem image is opened through dm-verity
  instmods dm-verity

  inst "$moddir/puavo-current-efi-boot-disk" /usr/bin/puavo-current-efi-boot-disk
  inst "$moddir/puavo-open-image-verity" /usr/bin/puavo-open-image-verity

  # Remove NVIDIA blacklist and configuration files
  rm -f "${initdir}/etc/modprobe.d/nvidia-blacklists-nouveau.conf" \
    "${initdir}/etc/modprobe.d/nvidia.conf" \
    "${initdir}/etc/modprobe.d/nvidia-kernel-common.conf"

  # Copy NVIDIA configuration if it exists
  if [ -d /etc/nvidia ]; then
    inst_dir /etc/nvidia
    cp -LR /etc/nvidia/* "${initdir}/etc/nvidia/"
  fi

  # Install hooks
  inst_hook pre-udev 90 "${moddir}/puavo-kernel-module-setup.sh"
  inst_hook pre-pivot 90 "${moddir}/puavo-rootmount.sh"
  inst_hook pre-pivot 91 "${moddir}/puavo-plymouth.sh"
  inst_hook cleanup 20 "${moddir}/puavo-nbd-server.sh"

  # Plymouth themes support displaying an image at runtime.
  # The initramfs filesystem is read-only,
  # so create a symlink to a writable location.
  ln -sf /run/plymouth-image.png \
    "${initdir}/usr/share/plymouth/themes/image.png"
}
