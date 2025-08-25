#!/bin/sh
set -eu

SCRIPT_DIRECTORY="$(dirname "$0")"
. "$SCRIPT_DIRECTORY/job-lib.sh"

submit_job "crypt_preinstall" \
           "boot_diskinstaller,crypt_preinstall" \
           "true" \
           "PUBLISH_HDD_1=crypt-preinstall-%VERSION%-%ARCH%-%BUILD%@%MACHINE%.qcow2"
