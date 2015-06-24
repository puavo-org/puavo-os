#!/bin/sh

set -eu

sudo apt-get update
sudo apt-get install -y --force-yes aptirepo-upload make devscripts equivs

sudo puavo-install-deps
make deb

version=$(dpkg-parsechangelog --show-field Version)
arch=$(dpkg-architecture -qDEB_BUILD_ARCH)

aptirepo-upload \
    -c "${CI_TARGET_DIST}" \
    -r "${APTIREPO_REMOTE}" \
    -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" \
    "../aptirepo_${version}_${arch}.changes"
