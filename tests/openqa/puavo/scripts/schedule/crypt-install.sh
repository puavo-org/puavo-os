#!/bin/sh
set -eu

SCRIPT_DIRECTORY="$(dirname "$0")"
. "$SCRIPT_DIRECTORY/job-lib.sh"

submit_job "crypt_install" \
           "boot_crypt_preinstall,install" \
           "false" \
           "HDD_1=crypt-preinstall-%VERSION%-%ARCH%-%BUILD%@%MACHINE%.qcow2" \
           "BOOTFROM=c"
