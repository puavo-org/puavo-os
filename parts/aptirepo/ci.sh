#!/bin/sh

set -eu
set -x

# Load environment. Is missing on Trusty...
. /etc/environment

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts

puavo-build-debian-dir
sudo puavo-install-deps debian/control
puavo-dch $(cat VERSION)
puavo-debuild

dpkg -i ../aptirepo-upload*.deb
apt-get install -f -y --force-yew

aptirepo-upload -r $APTIREPO_REMOTE -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" ../aptirepo*.changes
