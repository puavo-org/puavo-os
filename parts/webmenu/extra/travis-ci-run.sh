#!/bin/sh

set -eu

# Fix permissions
sudo chmod 1777 /dev/shm

sh -e /etc/init.d/xvfb start &
sleep 2

# NW_NAME="node-webkit-v0.4.1-linux-ia32"
NW_NAME="node-webkit-v0.4.1-linux-x64"
NW_URL="https://s3.amazonaws.com/node-webkit/v0.4.1/$NW_NAME.tar.gz"

wget --continue $NW_URL

tar xzvf "$NW_NAME.tar.gz"

export NW="$PWD/$NW_NAME/nw"
export DISPLAY=:99.0

make test-nw-hidden
