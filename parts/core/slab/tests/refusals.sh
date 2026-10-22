#!/bin/sh
# Slab must refuse and must not chainload in two cases: a next stage below the
# list minimum, and a slab older than the floor.
set -u

. "$(dirname "$0")/helpers.sh"

build_slab

WORK=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "$WORK"; }
trap cleanup EXIT

FAILED=0

# Case 1: a next stage below the minimum. A copy of slab stamped as grub
# version 0, below the grub floor, stands in for an old next stage. It
# is refused before it is ever loaded, so its contents do not matter.
below_minimum="$WORK/below-minimum"
mkdir -p "$below_minimum"
stale_stage="$below_minimum/grubx64.efi"
cp "$BINARY_DIRECTORY/slab.efi" "$stale_stage"
"$REPOSITORY_ROOT/.aux/add-bootloader-version-section" "$stale_stage" grub 0
state=$(mktemp -d)
disk=$(make_boot_disk "$BINARY_DIRECTORY/slab.efi" "$stale_stage" \
  "$below_minimum")
cp "$OVMF_VARIABLES" "$state/vars.fd"
swtpm_start "$state"
output=$(boot_qemu "$state" "$disk")
swtpm_stop
rm -rf "$state"
assert_contains "below-minimum next stage refused" "$output" \
  "next stage version 0 below minimum $(component_floor grub), refusing"
assert_absent "below-minimum next stage not chainloaded" "$output" \
  "chainloading next stage"

# Case 2: a slab older than the floor. Boot once so slab self defines and
# raises the counter to the list version, then bump the counter out of band so
# the floor rises above this slab's list version, and boot again.
old_slab="$WORK/old-slab"
mkdir -p "$old_slab"
build_next_stage "$old_slab/grubx64.efi"
disk=$(make_boot_disk "$BINARY_DIRECTORY/slab.efi" "$old_slab/grubx64.efi" \
  "$old_slab")
state=$(mktemp -d)
cp "$OVMF_VARIABLES" "$state/vars.fd"
swtpm_start "$state"
boot_qemu "$state" "$disk" >/dev/null
swtpm_stop
# The write lock clears on the TPM reset a fresh swtpm performs, so these
# increments succeed and raise the floor above the list version.
swtpm_start "$state" tools
increment_counter 3
swtpm_stop
swtpm_start "$state"
output=$(boot_qemu "$state" "$disk")
swtpm_stop
rm -rf "$state"
assert_contains "old slab refused" "$output" \
  "this device could not start because its startup software is too old"
assert_absent "old slab not chainloaded" "$output" "chainloading next stage"

exit "$FAILED"
