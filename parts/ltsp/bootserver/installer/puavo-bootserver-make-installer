#!/bin/bash

set -eu

on_exit()
{
    set +e

    if [ -n "${installmediaroot}" ]; then
        umount "${dev}1"
        rmdir "${installmediaroot}"
    fi

    exit $exitvalue
}

usage_error()
{
    echo "ERROR: $1" >&2
    echo "Try '$0 --help' for more information". >&2
    return 1
}

exitvalue=1

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            shift
            echo "Usage: $0 DEV ISO"
            echo
            echo "Create a bootserver installer USB disk."
            echo
            echo "Example: $0 /dev/sdb /tmp/ubuntu-12.04.5-server-amd64.iso"
            echo
            echo "Options:"
            echo "    -h, --help                   print help and exit"
            echo
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage_error "invalid argument '$1'"
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -ne 2 ]; then
    usage_error "invalid number of arguments ($#), expected 2"
fi

dev="$1"
iso="$2"
shift 2

if [ "$(id -u)" -ne 0 ]; then
    usage_error 'you must be root (euid=0) to run this command'
fi

dd if=/dev/zero "of=${dev}" count=1 bs=1M

sfdisk --unit S "${dev}" <<EOF
2048,4194304,c,*
EOF

mkfs.vfat "${dev}1"

installmediaroot=

trap on_exit EXIT

installmediaroot=$(mktemp -d)

mount "${dev}1" "${installmediaroot}"

unetbootin method=diskimage "isofile=${iso}" installtype=USB "targetdrive=${dev}1" autoinstall=yes

mkdir -p "$installmediaroot/preseed"
cp syslinux.cfg "$installmediaroot"
cp puavo-bootserver*.cfg "$installmediaroot/preseed"
cp puavo-bootserver-fix-partitions "$installmediaroot"
cp "${installmediaroot}/menu.c32" "${installmediaroot}/vesamenu.c32"

echo -n "user-fullname: "
read user_fullname

if [ -n "$user_fullname" ]; then
    user=""
    while true; do
        echo -n "user: "
        read user
        [ -n "$user" ] || {
            echo 'empty username not allowed' >&2
            continue
        }
        break
    done
    while true; do
        echo -n "password: "
        read -s password1
        echo
        [ -n "$password1" ] || {
            echo 'empty password not allowed' >&2
            continue
        }
        echo -n "verify password: "
        read -s password2
        echo
        [ "$password1" = "$password2" ] || {
            echo 'passwords do not match' >&2
            continue
        }
        break
    done
    echo "d-i passwd/user-fullname string $user_fullname" >> "$installmediaroot/preseed/puavo-bootserver.cfg"
    echo "d-i passwd/username string $user" >> "$installmediaroot/preseed/puavo-bootserver.cfg"
    echo "d-i passwd/user-password password $password1" >> "$installmediaroot/preseed/puavo-bootserver.cfg"
    echo "d-i passwd/user-password-again password $password1" >> "$installmediaroot/preseed/puavo-bootserver.cfg"
fi

exitvalue=0
