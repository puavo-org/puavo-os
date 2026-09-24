#!/bin/sh
# Boots with a revocation list one version behind the floor and refuses
# one two behind. Without the allow-previous-revocation-list feature,
# one behind is refused too. The floor is raised between boots with
# tpm2-tools, which puts the list of the same build behind, so no rebuild is
# needed.
set -u

. "$(dirname "$0")/helpers.sh"

OUTDATED_LIST_MESSAGE='this device could not start because its startup software is too old'

build_slab

WORK=$(mktemp --directory)
DEFAULT_STATE=$(mktemp --directory)
STRICT_STATE=$(mktemp --directory)
cleanup() {
  swtpm_stop
  rm --recursive --force "$WORK" "$DEFAULT_STATE" "$STRICT_STATE"
}
trap cleanup EXIT

# Raises the floor by incrementing the counter. A fresh swtpm resets the
# TPM, which removes the write lock.
#   $1  state directory
#   $2  how many versions to raise the floor by
raise_floor_by() {
  swtpm_start "$1" tools
  increment_counter "$2"
  swtpm_stop
}

# Boots one disk against a TPM state and prints the serial output.
#   $1  state directory
#   $2  boot disk
boot_once() {
  swtpm_start "$1"
  boot_qemu "$1" "$2"
  swtpm_stop
}

FAILED=0

build_next_stage "$WORK/grubx64.efi"
mkdir --parents "$WORK/default-disk" "$WORK/strict-disk"
default_disk=$(make_boot_disk "$BINARY_DIRECTORY/slab.efi" \
  "$WORK/grubx64.efi" "$WORK/default-disk")
prepare_variables "$DEFAULT_STATE"

# The first boot defines the counter and sets the floor to the list version.
first_boot_log=$(boot_once "$DEFAULT_STATE" "$default_disk")
assert_contains "the first boot reached chainload" "$first_boot_log" \
  "chainloading next stage"

# One version behind boots, and the counter is not raised.
raise_floor_by "$DEFAULT_STATE" 1
one_behind_log=$(boot_once "$DEFAULT_STATE" "$default_disk")
assert_contains "a list one version behind booted" "$one_behind_log" \
  "chainloading next stage"
assert_absent "a list one version behind did not raise the counter" \
  "$one_behind_log" "raising counter"

# Two versions behind is refused.
raise_floor_by "$DEFAULT_STATE" 1
two_behind_log=$(boot_once "$DEFAULT_STATE" "$default_disk")
assert_contains "a list two versions behind was refused" "$two_behind_log" \
  "$OUTDATED_LIST_MESSAGE"
assert_absent "a list two versions behind did not chainload" "$two_behind_log" \
  "chainloading next stage"

# Without the feature, on a fresh TPM, one version behind is refused.
strict_binary=$(build_without_defaults "$WORK/strict")
strict_disk=$(make_boot_disk "$strict_binary" "$WORK/grubx64.efi" \
  "$WORK/strict-disk")
prepare_variables "$STRICT_STATE"

strict_first_boot_log=$(boot_once "$STRICT_STATE" "$strict_disk")
assert_contains "without the feature the first boot reached chainload" \
  "$strict_first_boot_log" "chainloading next stage"

raise_floor_by "$STRICT_STATE" 1
without_feature_log=$(boot_once "$STRICT_STATE" "$strict_disk")
assert_contains "without the feature one version behind is refused" \
  "$without_feature_log" "$OUTDATED_LIST_MESSAGE"
assert_absent "without the feature one version behind did not chainload" \
  "$without_feature_log" "chainloading next stage"

exit "$FAILED"
