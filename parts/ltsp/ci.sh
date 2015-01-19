#!/bin/sh

set -eu
set -x

# Workaround the environment issue on Trusty
. /etc/environment

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts aptirepo-upload

sudo puavo-install-deps debian.default/control
if [ "${CI_TARGET_ARCH}" = i386 ]; then
    make deb
else
    make deb-binary-arch
fi

git_branch=$(echo "${GIT_BRANCH}" | cut -d / -f 2)
aptirepo_branch=git-"${git_branch}"

version=$(dpkg-parsechangelog | sed -r -n 's/^Version: //p')
[ -n "${version}" ] || {
    echo "Could not parse package version" >&2
    exit 1
}

build_arch=$(dpkg-architecture -qDEB_BUILD_ARCH)
changes_file="../puavo-ltsp_${version}_${build_arch}.changes"

aptirepo-upload -r "${APTIREPO_REMOTE}" -b "${aptirepo_branch}" "${changes_file}"
