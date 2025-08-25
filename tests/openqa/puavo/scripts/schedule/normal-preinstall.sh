#!/bin/sh
set -eu

SCRIPT_DIRECTORY="$(dirname "$0")"
. "$SCRIPT_DIRECTORY/job-lib.sh"

submit_job "normal_preinstall" \
           "boot_diskinstaller,normal_preinstall" \
           "true" \
           "PUBLISH_HDD_1=normal-preinstall-%VERSION%-%ARCH%-%BUILD%@%MACHINE%.qcow2"
