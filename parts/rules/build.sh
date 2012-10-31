#!/bin/sh

set -eu

cleanup() {
  test -n "$srccopydir" && rm -rf $srccopydir
}

trap cleanup EXIT

basedir=/virtualtmp/$USER
mirror=http://localhost:3142/fi.archive.ubuntu.com/ubuntu

srcdir=$(dirname $0)
srccopydir=$(mktemp -d /tmp/ltsp-builder-$USER.XXXXXXXXXX)

cp -a $srcdir $srccopydir
sudo env LTSP_BUILD_CLIENT_DIR=$srccopydir/ltsp-build-client \
       $srccopydir/ltsp-build-client/ltsp-build-client \
       --arch           i386 \
       --base           $basedir \
       --config         $srccopydir/ltsp-build-client/config \
       --mirror         $mirror \
       --purge-chroot   \
       --serial-console \
       --skipimage
