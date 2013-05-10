#!/bin/bash

set -eu

installmediaroot="$1"

mkdir -p "$installmediaroot/preseed"
cp syslinux.cfg "$installmediaroot"
cp puavo-bootserver*.cfg "$installmediaroot/preseed"
cp puavo-bootserver-fix-partitions "$installmediaroot"

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
