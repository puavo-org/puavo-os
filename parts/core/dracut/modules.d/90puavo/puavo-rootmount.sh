#!/bin/sh

# Todo: Duplicated
for x in $(cat /proc/cmdline); do
    if [ "$x" = "init=/sbin/init-puavo" ]; then
        BOOT=puavo
        break
    fi
done

# Todo: Duplicated
panic() {
    echo "PANIC: $1" >&2
    echo "Dropping to emergency shell..." >&2
    emergency_shell -n "Panic occurred: $1"
}

test "$BOOT" = "puavo" || exit 0

rootmnt="/sysroot"

PUAVO_HOSTTYPE=''
PUAVO_IMAGE_LOAD_TO_RAM=0
PUAVO_IMAGE_PATH=
PUAVO_IMAGE_OVERLAY=
PUAVO_LVM_VG="puavo"
PUAVO_ROOT_DEVICE=
ROOT_IN_BTRFS=0

for x in $(cat /proc/cmdline); do
    case "$x" in
        puavo.hosttype=*)
            PUAVO_HOSTTYPE="${x#puavo.hosttype=}"
            ;;
        puavo.image.load_to_ram=true)
            PUAVO_IMAGE_LOAD_TO_RAM=1
            ;;
        puavo.image.overlay=*)
            PUAVO_IMAGE_OVERLAY="${x#puavo.image.overlay=}"
            ;;
        puavo.image.path=*)
            PUAVO_IMAGE_PATH="${x#puavo.image.path=}"
            ;;
        root=/dev/*)
            PUAVO_ROOT_DEVICE="${x#root=}"
            ;;
        root=LABEL=*)
            PUAVO_ROOT_DEVICE="/dev/disk/by-label/${x#root=LABEL=}"
            ROOT_IN_BTRFS=1
            ;;
        root=UUID=*)
            PUAVO_ROOT_DEVICE="/dev/disk/by-uuid/${x#root=UUID=}"
            ROOT_IN_BTRFS=1
            ;;
    esac
done

# If the root device was not set in kernel parameters, we have to find it
# ourselves. However, we must consider there being multiple bootable disks
# such as mirrored RAID devices.
if [ -z "${PUAVO_ROOT_DEVICE}" ]; then
  echo "Root device is not set in kernel parameters. Attempting to find it..."

  # Todo: Can we get rid of this?
  # It seems we have to wait for udevs to finish loading, because
  # otherwise commands such as 'lsblk' fail to find block devices.
  # You might consider running this hook later such as during
  # mount instead of pre-mount phase, but I had trouble with that.
  # Somehow this hook had no effect (not executed?) and systemd
  # initrd-switch-root.service failed.
  echo "Waiting for storage devices to become fully available..."
  udevadm settle
  echo "Going through storage devices in order to find the boot device..."

  # Attempt to find out the boot disk using EFI variables
  POTENTIAL_BOOT_DEVICE=$(puavo-current-efi-boot-disk)
  echo "Potential boot device: ${POTENTIAL_BOOT_DEVICE:-unknown}"

  # If we found out the boot device, search for the first bootable root
  # partition and assign it as the root device.
  # Otherwise, search for any bootable root partition.
  if [ -n "${POTENTIAL_BOOT_DEVICE}" ]; then
    DEVICE_LIST=$(lsblk -lnp -o NAME "${POTENTIAL_BOOT_DEVICE}")
  else
    DEVICE_LIST=$(lsblk -lnp -o NAME)
  fi

  for device in $DEVICE_LIST; do
    if blkid "$device" | grep -q 'TYPE="btrfs"'; then
      PUAVO_ROOT_DEVICE=$device
      ROOT_IN_BTRFS=1
      echo "Selecting root device: $PUAVO_ROOT_DEVICE"
      break
    fi
  done

  if [ -z "${PUAVO_ROOT_DEVICE}" ]; then
    echo "Error: Failed to find the root device. Boot will likely fail."

    # As a last resort, we try to find a device with a label 'puavo'
    PUAVO_ROOT_DEVICE="/dev/disk/by-label/puavo"
  fi
fi

echo "Boot device: ${PUAVO_ROOT_DEVICE:-unknown}"

if [ "$ROOT_IN_BTRFS" = 0 ]; then
  lvm vgchange -a y "$PUAVO_LVM_VG"
fi

update_image_copy_progress() {
  # it is important this does not write to stdout or stderr
  # because that would corrupt the image
  local progress
  while read progress; do
    plymouth system-update "--progress=${progress}"
  done
}

# We need to mount the root device manually in pre-mount stage.
# You might attempt to execute this script during the mount stage
# when you'd expect the root to be mounted for you.
# However, it seems that Dracut unmounts the root device, because it's 
# considered "unusable" in our case, likely due to missing folders (e.g. /dev).
# See:
# https://github.com/dracutdevs/dracut/blob/5d2bda46f4e75e85445ee4d3bd3f68bf966287b9/modules.d/99base/init.sh#L234
# https://github.com/dracutdevs/dracut/blob/5d2bda46f4e75e85445ee4d3bd3f68bf966287b9/modules.d/99base/dracut-lib.sh#L750
if [ -n "$PUAVO_ROOT_DEVICE" ]; then
    mount "$PUAVO_ROOT_DEVICE" "$rootmnt"
fi

loopmount_image()
{
    local image_fs_size image_fs_type imagepath tmpfs_imagepath tmpfs_size

    if [ ! -f "${rootmnt}${PUAVO_IMAGE_PATH}" ]; then
      panic "${rootmnt}${PUAVO_IMAGE_PATH} does not exist!"
    fi

    mkdir -p /host
    mount -o move "$rootmnt" /host

    imagepath="/host/${PUAVO_IMAGE_PATH#/}"

    image_fs_type="squashfs"
    image_fs_size=$(stat -c %s "$imagepath")

    modprobe loop
    modprobe "$image_fs_type"

    if [ "$PUAVO_IMAGE_LOAD_TO_RAM" -eq 1 ]; then
      mkdir -p /imagetmp

      if [ -z "$image_fs_size" ]; then
        panic 'could not determine filesystem size'
      fi

      # XXX is this extra allocation for tmpfs correct?
      # XXX why these numbers?
      tmpfs_size=$(($image_fs_size + 32 * 1024 * 1024))
      mount -t tmpfs -o size="$image_fs_size" none /imagetmp

      plymouth display-message --text='Copying system to RAM'

      tmpfs_imagepath="/imagetmp/${imagepath##*/}"
      {
        pv -n "$imagepath" 3>&1 1>&2 2>&3 3>&- | update_image_copy_progress
      } > "$tmpfs_imagepath" 2>&1
      imagepath="$tmpfs_imagepath"
    fi

    mount -r -t "$image_fs_type" -o loop "$imagepath" "$rootmnt"
    ret=$?

    if [ "$ret" -gt 0 ]; then
      panic "Failed to loop mount ${imagepath} to ${rootmnt}"
    fi
}

do_union_mount()
{
    cow=$1

    mkdir -p /rofs
    mount -o move "$rootmnt" /rofs

    modprobe overlay
    mkdir -p "${cow}/rootdir" "${cow}/workdir"
    mount -t overlay \
          -o "upperdir=${cow}/rootdir,lowerdir=/rofs,workdir=${cow}/workdir" \
          overlay "$rootmnt"

    mkdir -p "${rootmnt}/rofs"
    mount -o move /rofs "${rootmnt}/rofs"
}

do_union_mount_temporary()
{
    mkdir -p /cow
    mount -t tmpfs -o mode=0755 tmpfs /cow

    do_union_mount /cow

    mkdir -p "${rootmnt}/cow"
    mount -o move /cow "${rootmnt}/cow"
}

do_union_mount_persistent()
{
    cow="/imageoverlays/${PUAVO_IMAGE_NAME}/${PUAVO_IMAGE_OVERLAY}"
    mkdir -p "$cow"
    do_union_mount "$cow"
}

mount_puavo_partition() {
    name=$1

    if [ "$ROOT_IN_BTRFS" = 0 \
      -a ! -b "/dev/mapper/${PUAVO_LVM_VG}-${name}" ]; then
        return 0
    fi

    mkdir -p "/${name}"

    if [ "$ROOT_IN_BTRFS" = 1 ]; then
        # XXX should -o noatime also used with btrfs?
        mount -o "subvol=${name}" "$PUAVO_ROOT_DEVICE" "/${name}" || return 1
        return 0
    fi

    OPTIONS='-o noatime'

    if mount $OPTIONS "/dev/mapper/${PUAVO_LVM_VG}-${name}" "/${name}"; then
        return 0
    fi

    # FORCE fsck if mount failed again (first try automatic, then -y)
    if ! fsck -fpv "/dev/mapper/${PUAVO_LVM_VG}-${name}"; then
        fsck -fvy "/dev/mapper/${PUAVO_LVM_VG}-${name}" || true
    fi

    mount $OPTIONS "/dev/mapper/${PUAVO_LVM_VG}-${name}" "/${name}" || return 1
}

move_puavo_partition()
{
    name=$1

    mkdir -p "${rootmnt}/${name}"
    mount -o move "/${name}" "${rootmnt}/${name}"
}

loopmount_used=0
if [ -n "$PUAVO_IMAGE_PATH" ]; then
    loopmount_image
    loopmount_used=1
fi

if [ -f "${rootmnt}/etc/puavo-image/name" ]; then
    PUAVO_IMAGE_NAME=$(cat "${rootmnt}/etc/puavo-image/name")
else
    PUAVO_IMAGE_NAME='default'
fi

if [ "$loopmount_used" -gt 0 -a -n "${PUAVO_IMAGE_PATH}" -a -n "${PUAVO_IMAGE_OVERLAY}" ]; then
    {
        mount_puavo_partition imageoverlays \
            && do_union_mount_persistent    \
            && move_puavo_partition imageoverlays
    } || panic "could not mount persistent overlay"
else
    do_union_mount_temporary
fi

# If using a loopmount image, move the /images partition under loop mounted
# root and remount the partition as writable
if [ "$loopmount_used" -gt 0 ]; then
    if [ "$ROOT_IN_BTRFS" = 1 ]; then
        if [ "$PUAVO_HOSTTYPE" = 'diskinstaller' ]; then
            target_dir="${rootmnt}/.puavoinstaller"
        else
            target_dir="${rootmnt}/.puavo"
        fi
    else
        target_dir="${rootmnt}/images"
    fi
    mkdir -p "$target_dir"
    # XXX what to do here when $PUAVO_IMAGE_LOAD_TO_RAM is used?
    mount -o move /host "$target_dir"
    mount -o remount,noatime,rw "$target_dir"
fi

[ -z "${rootmnt}" ] && panic "rootmnt unknown in init-bottom"
[ -d "${rootmnt}/proc" ] || panic "rootmnt not mounted in init-bottom"
