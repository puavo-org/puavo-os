#!/bin/sh

set -eu
set -x

sudo apt-get update
sudo apt-get install -y puavo-devscripts

debbox_url="$1"

puavo-build-debian-dir
sudo puavo-install-deps debian/control
puavo-dch $(jq -r  .version package.json)
puavo-debuild
exit 1
puavo-upload-packages "$debbox_url" ../debbox*.changes "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)"
