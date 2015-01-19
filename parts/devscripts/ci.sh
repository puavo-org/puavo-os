#!/bin/sh

set -eu
set -x

env

sudo apt-get update
sudo apt-get install -y --force-yes aptirepo-upload make devscripts equivs git-core

sudo make install-deb-debs
make deb

aptirepo-upload -r $APTIREPO_REMOTE -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" ../puavo-devscripts*.changes
