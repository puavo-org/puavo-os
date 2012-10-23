#!/bin/sh

set -e

cleanup() {
  test -n "$srcdir" && rm -rf $srcdir
}

usage() {
  echo "Usage: $(basename $0) boot|ltsp hostname" > /dev/stderr
  exit 1
}

trap cleanup EXIT

if [ "$(id -u)" = "0" ]; then
  echo "Do not run me as root" > /dev/stderr
  exit 1
fi

hosttype=$1
hostname=$2

test -z "$hosttype" -o -z "$hostname" && usage

srcdir=$(mktemp -d /tmp/ltsp-build-$USER-$$.XXXXXXXXXXX)
cp -a "$(dirname $0)" $srcdir

case "$hosttype" in
  boot)
    extraopts="--addpkg ltsp-server-standalone \
	       --arch amd64 \
    	       --dest /images/$hostname \
    	       --flavour=server \
    	       --hostname $hostname \
    	       --suite=precise"
    ;;
  ltsp)
    extraopts="--addpkg ltsp-client-core \
	       --arch i386 \
    	       --dest /images/$hostname \
    	       --flavour=generic \
    	       --hostname $hostname \
    	       --suite=quantal"
    ;;
  *)
    usage
    ;;
esac

sudo \
  vmbuilder kvm ubuntu \
    --addpkg linux-image-generic \
    --addpkg openssh-server \
    --user opinsys \
    --pass opinsys \
    --mirror http://10.246.131.53:9999/fi.archive.ubuntu.com/ubuntu \
    --debug \
    -v \
    --exec $srcdir/setup.sh \
    --rootsize 20480 \
    --tmp /virtualtmp \
    $extraopts
