#!/bin/sh

set -eu

arch=i386

cleanup() {
  test -n "$srccopydir" && rm -rf $srccopydir
}

sudo_for_ltsp() {
  sudo env LTSP_CUSTOM_PLUGINS="$srccopydir/ltsp-build-client/plugins" \
           PATH="$srccopydir/ltsp-build-client:$PATH" \
           setarch $arch \
           "$@"
}

trap cleanup EXIT

{
  set +u
  mode=$1
}

# we use the Ubuntu quantal-distribution as a default
distribution=${DISTRIBUTION:-quantal}
mirror=http://localhost:3142/fi.archive.ubuntu.com/ubuntu

# fasttmp should be mounted on a tmpfs partition
buildtmp=/virtualtmp
basedir=$buildtmp/$USER

srcdir=$(dirname $0)
srccopydir=$(mktemp -d /tmp/ltsp-builder-$USER.XXXXXXXXXX)

configfile=$srccopydir/ltsp-build-client/config/$distribution

build_date=$(date +%Y-%m-%d-%H%M%S)
build_name=$(git branch | awk '$1 == "*" { print $2 }')
build_version=ltsp-$distribution-$build_name-$build_date
build_logfile=$srcdir/log/$build_version-$mode.log

cp -pLR $srcdir $srccopydir

puppet_module_dirs=$srccopydir/ltsp-build-client/puppet/opinsys:$srccopydir/ltsp-build-client/puppet/ltsp

for mntpoint in dev/pts dev proc sys; do
  sudo umount -f $basedir/$arch/$mntpoint 2>/dev/null \
    || true
done

{
  case "$mode" in
    build)
      sudo_for_ltsp $srccopydir/ltsp-build-client/ltsp-build-client \
          --arch               $arch \
          --base               $basedir \
          --config             $configfile \
          --debconf-seeds      $srccopydir/ltsp-build-client/debconf.seeds \
          --dist               $distribution \
          --install-debs-dir   $srccopydir/ltsp-build-client/debs \
          --mirror             $mirror \
          --puppet-module-dirs $puppet_module_dirs \
          --purge-chroot       \
          --serial-console     \
          --skipimage
      ;;
    chroot)
      sudo_for_ltsp ltsp-chroot --base $basedir --mount-all
      ;;
    image)
      sudo_for_ltsp ltsp-chroot --base $basedir passwd
      ltspimage_name=$build_version-$arch.img
      sudo sh -c "
        mkdir -p $basedir/$arch/etc/ltsp; \
        echo $ltspimage_name > $basedir/$arch/etc/ltsp/this_ltspimage_name
      "

      # XXX ltsp-build-client --onlyimage ?
      sudo mksquashfs \
          $basedir/$arch /opt/ltsp/images/$ltspimage_name \
          -noappend -no-recovery -wildcards \
          -ef $srccopydir/ltsp-build-client/ltsp-update-image.excludes
      ;;
    update-chroot)
      sudo_for_ltsp ltsp-apply-puppet \
          --config             $configfile \
          --ltsp-chroot-opts   "--mount-all" \
          --puppet-module-dirs $puppet_module_dirs \
          --targetroot         "$basedir/$arch"
      ;;
    update-local)
      sudo_for_ltsp ltsp-apply-puppet \
          --config             $configfile \
          --puppet-module-dirs $puppet_module_dirs
      ;;
  esac
} 2>&1 | tee $build_logfile
