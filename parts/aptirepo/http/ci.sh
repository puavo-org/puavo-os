#!/bin/sh

set -eu
set -x

sudo apt-get update
sudo apt-get install -y puavo-devscripts

aptirepo_url="$1"

puavo-build-debian-dir
sudo puavo-install-deps debian/control
puavo-dch $(jq -r  .version package.json)
puavo-debuild
puavo-upload-packages "$aptirepo_url" ../aptirepo*.changes "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)"
