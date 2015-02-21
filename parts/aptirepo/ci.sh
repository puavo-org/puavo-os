#!/bin/sh

set -eu
set -x

# Load environment. Is missing on Trusty...
. /etc/environment

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts aptirepo-upload

sudo puavo-install-deps debian.default/control
make deb

aptirepo-upload -r $APTIREPO_REMOTE -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" ../aptirepo*.changes
