#!/bin/sh
set -eu

SCRIPT_DIRECTORY="$(dirname "$0")"
cd "$SCRIPT_DIRECTORY"

./crypt-preinstall.sh
./crypt-install.sh
