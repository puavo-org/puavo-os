#!/bin/sh

set -eu

cleanup() {
  test -n "$srccopydir" && rm -rf $srccopydir
}

run_sudo() {
  sudo env LTSP_CUSTOM_PLUGINS="$srccopydir/ltsp-build-client/plugins" \
           PATH="$srccopydir/ltsp-build-client:$PATH" \
           "$@"
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

cp -pLR $srcdir $srccopydir

puppet_module_dirs=$srccopydir/ltsp-build-client/puppet/opinsys:$srccopydir/ltsp-build-client/puppet/ltsp

{
  case "$mode" in
    build)
      run_sudo $srccopydir/ltsp-build-client/ltsp-build-client \
          --arch               $arch \
          --base               $basedir \
          --config             $srccopydir/ltsp-build-client/config \
          --debconf-seeds      $srccopydir/ltsp-build-client/debconf.seeds \
          --install-debs-dir   $srccopydir/ltsp-build-client/debs \
          --mirror             $mirror \
          --puppet-module-dirs $puppet_module_dirs \
          --purge-chroot       \
          --serial-console     \
          --skipimage
      ;;
    configure)
      run_sudo $srccopydir/ltsp-build-client/ltsp-chroot \
          --arch               $arch \
          --base               $basedir \
          --config             $srccopydir/ltsp-build-client/config \
          --mount-all \
          --puppet-module-dirs $puppet_module_dirs \
          true
      ;;
    chroot)
      run_sudo $srccopydir/ltsp-build-client/ltsp-chroot \
          --base $basedir \
          --mount-all
      ;;
    image)
      # XXX ltsp-build-client --onlyimage ?
      sudo mksquashfs \
             $basedir/$arch /images/$build_version-$arch.img \
             -noappend -no-progress -no-recovery -wildcards \
             -ef $srccopydir/ltsp-build-client/ltsp-update-image.excludes
      ;;
  esac
} 2>&1 | tee $build_logfile
