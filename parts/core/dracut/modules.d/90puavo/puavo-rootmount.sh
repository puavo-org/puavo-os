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

PUAVO_IMAGE_LOAD_TO_RAM=0
PUAVO_IMAGE_PATH=
PUAVO_IMAGE_OVERLAY=
PUAVO_LVM_VG="puavo"
PUAVO_ROOT_DEVICE=
ROOT_IN_BTRFS=0

for x in $(cat /proc/cmdline); do
    case "$x" in
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
        root=UUID=*)
            PUAVO_ROOT_DEVICE="/dev/disk/by-uuid/${x#root=UUID=}"
            ROOT_IN_BTRFS=1
            ;;
    esac
done

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
    local FSSIZE FSTYPE imagepath tmpfs_imagepath tmpfs_size

    if [ ! -f "${rootmnt}${PUAVO_IMAGE_PATH}" ]; then
      panic "${rootmnt}${PUAVO_IMAGE_PATH} does not exist!"
    fi

    mkdir -p /host
    mount -o move "$rootmnt" /host

    imagepath="/host/${PUAVO_IMAGE_PATH#/}"

    # Get the loop filesystem type if not set
    # fstype command sets FSTYPE and FSSIZE variables
    eval $(/usr/bin/fstype < "$imagepath")
    modprobe loop

    if [ -n "$FSTYPE" ]; then
      modprobe "$FSTYPE"
    else
      FSTYPE='unknown'
    fi

    if [ "$PUAVO_IMAGE_LOAD_TO_RAM" -eq 1 ]; then
      mkdir -p /imagetmp
      if [ -z "$FSSIZE" ]; then
        panic 'could not determine filesystem size for tmpfs'
      fi
      # XXX is this extra allocation for tmpfs correct?
      # XXX why these numbers?
      tmpfs_size=$(($FSSIZE + 32 * 1024 * 1024))
      mount -t tmpfs -o size="$FSSIZE" none /imagetmp

      plymouth display-message --text='Copying system to RAM'

      tmpfs_imagepath="/imagetmp/${imagepath##*/}"
      {
        pv -n "$imagepath" 3>&1 1>&2 2>&3 3>&- | update_image_copy_progress
      } > "$tmpfs_imagepath" 2>&1
      imagepath="$tmpfs_imagepath"
    fi

    mount -r -t "$FSTYPE" -o loop "$imagepath" "$rootmnt"
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
        target_dir="${rootmnt}/.btrfs"
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
