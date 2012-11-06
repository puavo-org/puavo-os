#!/bin/sh

set -eu

cleanup() {
  test -n "$srccopydir" && rm -rf $srccopydir
}

trap cleanup EXIT

{
  set +u
  mode=$1
}

arch=i386
basedir=/virtualtmp/$USER
mirror=http://localhost:3142/fi.archive.ubuntu.com/ubuntu

srcdir=$(dirname $0)
srccopydir=$(mktemp -d /tmp/ltsp-builder-$USER.XXXXXXXXXX)

build_date=$(date +%Y-%m-%d-%H%M%S)
build_name=$(git branch | awk '$1 == "*" { print $2 }')
build_version=ltsp-$build_name-$build_date
build_logfile=$srcdir/log/$build_version-$mode.log

cp -a $srcdir $srccopydir

{
  case "$mode" in
    build)
      sudo env LTSP_CUSTOM_PLUGINS="$srccopydir/ltsp-build-client/plugins" \
        $srccopydir/ltsp-build-client/ltsp-build-client \
          --arch               $arch \
          --base               $basedir \
          --config             $srccopydir/ltsp-build-client/config \
          --debconf-seeds      $srccopydir/ltsp-build-client/debconf.seeds \
          --install-debs-dir   $srccopydir/ltsp-build-client/debs \
          --mirror             $mirror \
          --purge-chroot       \
          --puppet-sources-dir $srccopydir/ltsp-build-client/puppet \
          --serial-console     \
          --skipimage
      ;;
    configure)
      sudo env LTSP_CUSTOM_PLUGINS="$srccopydir/ltsp-build-client/plugins" \
        $srccopydir/ltsp-build-client/ltsp-chroot \
          --base $basedir \
          --mount-all \
          --puppet-sources-dir $srccopydir/ltsp-build-client/puppet \
          --puppet-use-classes "organisation_adm_users"
      ;;
    image)
      sudo mksquashfs \
             $basedir/$arch /images/$build_version-$arch.img \
             -noappend -no-progress -no-recovery -wildcards \
             -ef $srccopydir/ltsp-build-client/ltsp-update-image.excludes
      ;;
  esac
} 2>&1 | tee $build_logfile
