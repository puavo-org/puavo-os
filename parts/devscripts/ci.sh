#!/bin/sh

set -eu
set -x

env

sudo apt-get update
sudo apt-get install -y --force-yes aptirepo-upload make equivs

sudo make install-deb-deps
if [ "${CI_TARGET_ARCH}" = i386 ]; then
    make deb
else
    make deb-binary-arch
fi

aptirepo-upload -r $APTIREPO_REMOTE -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" ../puavo-devscripts*.changes
