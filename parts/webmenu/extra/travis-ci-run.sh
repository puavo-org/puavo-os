#!/bin/sh

set -eu

sh -e /etc/init.d/xvfb start &
sleep 2

# NW_NAME="node-webkit-v0.4.1-linux-ia32"
NW_NAME="node-webkit-v0.4.1-linux-x64"
NW_URL="https://s3.amazonaws.com/node-webkit/v0.4.1/$NW_NAME.tar.gz"

wget -c $NW_URL

tar xzvf "$NW_NAME.tar.gz"

export NW="$PWD/$NW_NAME/nw"
export DISPLAY=:99.0

make test-nw-hidden
