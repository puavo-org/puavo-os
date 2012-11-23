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

# fasttmp should be mounted on a tmpfs partition
fasttmp=/virtualtmp
normaltmp=/opt/ltsp/images/tmp

reserving_user="$(cat $fasttmp/USER 2>/dev/null || true)"
if [ "$reserving_user" = "$USER" ]; then
  basedir=$fasttmp/$USER
else
  basedir=$normaltmp/$USER
fi

arch=i386
mirror=http://localhost:3142/fi.archive.ubuntu.com/ubuntu

srcdir=$(dirname $0)
srccopydir=$(mktemp -d /tmp/ltsp-builder-$USER.XXXXXXXXXX)

build_date=$(date +%Y-%m-%d-%H%M%S)
build_name=$(git branch | awk '$1 == "*" { print $2 }')
build_version=ltsp-$build_name-$build_date
build_logfile=$srcdir/log/$build_version-$mode.log

cp -pLR $srcdir $srccopydir

puppet_module_dirs=$srccopydir/ltsp-build-client/puppet/opinsys:$srccopydir/ltsp-build-client/puppet/ltsp

for tmp in $fasttmp $normaltmp; do
  for mntpoint in dev/pts dev proc sys; do
    run_sudo umount -f $tmp/$USER/$arch/$mntpoint 2>/dev/null \
      || true
  done
done

{
  case "$mode" in
    build)
      if [ "$basedir" = "$normaltmp/$USER" ]; then
        echo
        echo ">>>>> You got the slow lane for build!  I hope that is okay!"
        echo ">>>>> Use 'reserve' if you want the fast lane!"
        echo
        sleep 3
      fi

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
    chroot)
      run_sudo ltsp-chroot --base $basedir --mount-all
      ;;
    force-reserve)
      run_sudo sh -c "echo $USER > $fasttmp/USER"
      ;;
    free)
      run_sudo rm -rf $normaltmp/$USER
      run_sudo mv $fasttmp/$USER $normaltmp/$USER || true
      run_sudo rm -f $fasttmp/USER
      ;;
    image)
      # XXX ltsp-build-client --onlyimage ?
      run_sudo mksquashfs \
                 $basedir/$arch /opt/ltsp/images/$build_version-$arch.img \
                 -noappend -no-progress -no-recovery -wildcards \
                 -ef $srccopydir/ltsp-build-client/ltsp-update-image.excludes
      ;;
    reserve)
      fasttmp_user="$(cat $fasttmp/USER 2>/dev/null || true)"
      if [ -n "$fasttmp_user" ]; then
        echo "Fast lane is reserved by '$fasttmp_user'."
        echo "Talk to him/her, or use 'force-reserve'."
        exit 1
      else
        run_sudo sh -c "echo $USER > $fasttmp/USER"
      fi
      ;;
    update-chroot)
      run_sudo ltsp-apply-puppet \
          --config             $srccopydir/ltsp-build-client/config \
          --ltsp-chroot-opts   "--mount-all" \
          --puppet-module-dirs $puppet_module_dirs \
          --targetroot         "$basedir/$arch"
      ;;
    update-local)
      run_sudo ltsp-apply-puppet \
          --config             $srccopydir/ltsp-build-client/config \
          --puppet-module-dirs $puppet_module_dirs
      ;;
  esac
} 2>&1 | tee $build_logfile
