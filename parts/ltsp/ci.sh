#!/bin/sh

set -eu
set -x

# Workaround the environment issue on Trusty
. /etc/environment

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts

sudo puavo-install-deps debian.default/control
make deb

if [ -n "${APTIREPO_REMOTE:-}" ]; then
    sudo apt-get install -y --force-yes aptirepo-upload

    if [ -z "${GIT_BRANCH:-}" ]; then
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    fi

    local_git_branch=$(echo "${GIT_BRANCH}" | cut -d / -f 2)
    aptirepo_branch=git-"${local_git_branch}"

    version=$(dpkg-parsechangelog --show-field Version)
    build_arch=$(dpkg-architecture -qDEB_BUILD_ARCH)
    changes_file="../puavo-ltsp_${version}_${build_arch}.changes"
    aptirepo-upload -r "${APTIREPO_REMOTE}" -b "${aptirepo_branch}" "${changes_file}"
fi
