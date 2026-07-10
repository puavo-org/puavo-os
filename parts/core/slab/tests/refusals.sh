#!/bin/sh
# Slab must refuse and must not chainload in two cases: a next stage below the
# list minimum, and a slab older than the floor.
set -u

. "$(dirname "$0")/helpers.sh"

build_slab

WORK=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "$WORK"; }
trap cleanup EXIT

COUNTER_INDEX=0x01514B00
FAILED=0

# Case 1: a next stage below the minimum. A copy of slab stamped as grub
# version 0, below the grub minimum of 1, stands in for an old next stage. It
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
  "next stage version 0 below minimum 1, refusing"
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
swtpm socket --tpm2 --tpmstate dir="$state" \
  --ctrl type=tcp,port=2322 --server type=tcp,port=2321 --flags startup-clear &
raise_process_id=$!
sleep 1
export TPM2TOOLS_TCTI="swtpm:host=127.0.0.1,port=2321"
increment_count=0
while [ "$increment_count" -lt 3 ]; do
  tpm2_nvincrement "$COUNTER_INDEX" >/dev/null 2>&1
  increment_count=$((increment_count + 1))
done
unset TPM2TOOLS_TCTI
kill "$raise_process_id" 2>/dev/null
wait "$raise_process_id" 2>/dev/null
swtpm_start "$state"
output=$(boot_qemu "$state" "$disk")
swtpm_stop
rm -rf "$state"
assert_contains "old slab refused" "$output" \
  "this device could not start because its startup software is too old"
assert_absent "old slab not chainloaded" "$output" "chainloading next stage"

exit "$FAILED"
