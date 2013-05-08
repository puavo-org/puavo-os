#!/bin/sh

set -eu

mediaroot=$1

mkdir -p "$1/preseed"
cp syslinux.cfg "$1"
cp puavo-bootserver*.cfg "$1/preseed"
cp puavo-bootserver-fix-partitions "$1"
