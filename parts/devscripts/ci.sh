#!/bin/sh

set -eu

sudo apt-get update
sudo apt-get install -y --force-yes aptirepo-upload make devscripts equivs

sudo make install-deb-deps
make deb

aptirepo-upload \
    -c "${CI_TARGET_DIST}" \
    -r "${APTIREPO_REMOTE}" \
    -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" \
    ../puavo-devscripts*.changes
