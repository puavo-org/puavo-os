#!/bin/sh
set -eu

SCRIPT_DIRECTORY="$(dirname "$0")"
cd "$SCRIPT_DIRECTORY"

./normal-preinstall.sh
./normal-install.sh

