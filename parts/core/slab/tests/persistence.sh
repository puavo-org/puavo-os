#!/bin/sh
# Boots slab twice against the same swtpm NV state. The first boot self defines
# the counter and base and raises to the list version. The second finds them
# persisted, so the floor is stable, no raise happens, and PCR 7 is identical.
# NV survives a TPM reset and PCR values do not, so an identical PCR 7 proves
# the base extension is deterministic.
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

boot_once() {
  swtpm_start "$STATE"
  boot_qemu "$STATE" "$disk"
  swtpm_stop
}

pcr_seven_of() {
  printf '%s' "$1" | sed -n 's/^PCR 7 after extend: //p' | head -1
}

first=$(boot_once)
second=$(boot_once)
first_pcr=$(pcr_seven_of "$first")
second_pcr=$(pcr_seven_of "$second")

FAILED=0
assert_contains "first boot raised the counter" "$first" "raising counter"
assert_absent "second boot did not raise the counter" "$second" \
  "raising counter"
assert_contains "first boot reached chainload" "$first" \
  "chainloading next stage"
assert_contains "second boot reached chainload" "$second" \
  "chainloading next stage"

if [ -n "$first_pcr" ] && [ "$first_pcr" = "$second_pcr" ]; then
  echo "PASS: PCR 7 identical across both boots ($first_pcr)"
else
  echo "FAIL: PCR 7 differs (first=$first_pcr second=$second_pcr)"
  FAILED=1
fi
exit "$FAILED"
