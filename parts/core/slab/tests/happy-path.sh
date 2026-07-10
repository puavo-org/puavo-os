#!/bin/sh
# Happy path: slab enforces the rollback floor and chainloads real GRUB, which
# finds its configuration by filesystem UUID and loads the unicode font.
set -u

. "$(dirname "$0")/helpers.sh"

build_slab

WORK=$(mktemp -d)
STATE=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "$WORK" "$STATE"; }
trap cleanup EXIT

build_next_stage "$WORK/grubx64.efi"
disk=$(make_boot_disk "$BINARY_DIRECTORY/slab.efi" "$WORK/grubx64.efi" "$WORK")

prepare_variables "$STATE"
swtpm_start "$STATE"
output=$(boot_qemu "$STATE" "$disk")
echo "$output"

FAILED=0
assert_contains "slab chainloaded the next stage" "$output" \
  "chainloading next stage"
assert_contains "the next stage read its configuration" "$output" \
  "$NEXT_STAGE_MARKER"
assert_contains "the next stage loaded the unicode font" "$output" "Unifont"
assert_absent "slab did not refuse" "$output" "refusing"
exit "$FAILED"
