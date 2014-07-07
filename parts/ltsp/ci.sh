#!/bin/sh

set -eu
set -x

# Workaround the environment issue on Trusty
. /etc/environment

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts aptirepo-upload

sudo puavo-install-deps debian.default/control
make deb

git_branch=$(echo "${GIT_BRANCH}" | cut -d / -f 2)
aptirepo_branch=git-"${git_branch}"

version=$(dpkg-parsechangelog --show-field Version)
build_arch=$(dpkg-architecture -qDEB_BUILD_ARCH)
changes_file="../puavo-ltsp_${version}_${build_arch}.changes"

aptirepo-upload -r "${APTIREPO_REMOTE}" -b "${aptirepo_branch}" "${changes_file}"
