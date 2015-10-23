#!/bin/sh

set -x
set -eu

sudo apt-get update
sudo apt-get install -y --force-yes puavo-devscripts aptirepo-upload node-webkit jq
sudo apt-get install -y wmctrl gnome-themes-extras socat netcat-openbsd libnotify-bin xvfb

# XXX: Why node-webkit does not install these?
sudo apt-get install -y libgconf2.0 libnss3

Xvfb :99 -screen 0 1024x768x24 &> /cirun/xvfb.log &

puavo-build-debian-dir -v
puavo-dch $(jq -r  .version package.json)
sudo puavo-install-deps

# XXX: For some random reason ci user has no permissions to write
# /home/ci/.npmrc
# Workaround by using sudo.
sudo npm set registry http://registry.npmjs.org/

export DISPLAY=:99
puavo-debuild

aptirepo-upload -r $APTIREPO_REMOTE -b "git-$(echo "$GIT_BRANCH" | cut -d / -f 2)" ../webmenu*.changes
