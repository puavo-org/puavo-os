#!/bin/sh

set -eu
set -x

sudo apt-get update
sudo apt-get install -y puavo-devscripts

debbox_url="$1"

puavo-build-debian-dir
puavo-dch $(jq -r  .version package.json)
sudo puavo-install-deps debian/control
puavo-debuild
puavo-upload-packages "$debbox_url" ../puavo*.changes "git-${GIT_BRANCH}"
