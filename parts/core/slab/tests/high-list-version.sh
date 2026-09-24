#!/bin/sh
# Boots with a high list version, so the counter is raised many steps
# in one boot. Checks that the raise does not trigger the TPM dictionary
# attack lockout, and that a power loss during the raise leaves a device that
# still boots. The times printed are from a software TPM.
set -u

. "$(dirname "$0")/helpers.sh"

HIGH_VERSION=128

# Large enough that the raise is still running when the power is cut.
INTERRUPTED_VERSION=$((32 * 1024))

WORK=$(mktemp --directory)
STATE=$(mktemp --directory)
cleanup() {
  swtpm_stop
  rm --recursive --force "$WORK" "$STATE"
}
trap cleanup EXIT

# Prints the dictionary attack lockout counter. Needs a swtpm started for
# tpm2-tools.
lockout_counter() {
  tpm2_getcap properties-variable \
    | sed --quiet 's/^TPM2_PT_LOCKOUT_COUNTER: //p'
}

boot_once() {
  swtpm_start "$STATE"
  boot_qemu "$STATE" "$disk"
  swtpm_stop
}

# Boots and cuts the power one second after the raise has started, then
# prints the serial output.
boot_and_cut_power() {
  swtpm_start "$STATE"
  boot_qemu "$STATE" "$disk" >/dev/null &
  boot_process_id=$!

  while kill -0 "$boot_process_id" 2>/dev/null \
    && ! grep --text --quiet --fixed-strings "raising counter" \
      "$STATE/serial.log" 2>/dev/null; do
    sleep 0.1
  done
  # Nothing is printed during the raise. The raise to the interrupted
  # version takes many seconds on swtpm, so one second in, it is partway.
  sleep 1

  # Stopping timeout stops the machine it runs.
  pkill --signal TERM --parent "$boot_process_id" --exact timeout
  wait "$boot_process_id" 2>/dev/null
  swtpm_stop
  cat "$STATE/serial.log"
}

FAILED=0

build_slab "$HIGH_VERSION" >&2
build_next_stage "$WORK/grubx64.efi"
disk=$(make_boot_disk "$BINARY_DIRECTORY/slab.efi" "$WORK/grubx64.efi" "$WORK")
prepare_variables "$STATE"

swtpm_start "$STATE" tools
lockout_before_boot=$(lockout_counter)
swtpm_stop

started=$(date +%s)
boot_log=$(boot_once)
elapsed=$(($(date +%s) - started))

assert_contains "the counter was raised" "$boot_log" "raising counter"
assert_contains "the boot reached chainload" "$boot_log" \
  "chainloading next stage"
echo "INFO: a boot raising the counter by ${HIGH_VERSION} took ${elapsed}s"

swtpm_start "$STATE" tools
attributes=$(tpm2_nvreadpublic "$COUNTER_INDEX")
base_attributes=$(tpm2_nvreadpublic "$BASE_INDEX")
lockout_after_boot=$(lockout_counter)
version_after_boot=$(slab_version)
swtpm_stop

assert_contains "the counter is exempt from lockout" "$attributes" "no_da"
assert_contains "the base is exempt from lockout" "$base_attributes" "no_da"

if [ "$lockout_before_boot" = "$lockout_after_boot" ]; then
  echo "PASS: the lockout counter did not change (${lockout_before_boot})"
else
  echo "FAIL: the lockout counter changed" \
    "(${lockout_before_boot} -> ${lockout_after_boot})"
  FAILED=1
fi

if [ "$version_after_boot" = "$HIGH_VERSION" ]; then
  echo "PASS: the counter reached the list version"
else
  echo "FAIL: the counter is at ${version_after_boot}, not ${HIGH_VERSION}"
  FAILED=1
fi

# Cut the power during a raise on a fresh TPM. The counter cannot go back,
# so the next boot must continue from where the raise stopped.
rm --recursive --force "$STATE"
STATE=$(mktemp --directory)
prepare_variables "$STATE"

build_slab "$INTERRUPTED_VERSION" >&2
disk=$(make_boot_disk "$BINARY_DIRECTORY/slab.efi" "$WORK/grubx64.efi" "$WORK")

power_cut_log=$(boot_and_cut_power)

assert_contains "the raise started" "$power_cut_log" "raising counter"
assert_absent "the power was cut before the raise finished" "$power_cut_log" \
  "chainloading next stage"

swtpm_start "$STATE" tools
version_after_power_cut=$(slab_version)
swtpm_stop

# Above the configured version shows the raise ran beyond a regular boot.
if [ "$version_after_power_cut" -gt "$(configured_version)" ] \
  && [ "$version_after_power_cut" -lt "$INTERRUPTED_VERSION" ]; then
  echo "PASS: the raise stopped partway (${version_after_power_cut})"
else
  echo "FAIL: the counter is at ${version_after_power_cut}, not between" \
    "$(configured_version) and ${INTERRUPTED_VERSION}"
  FAILED=1
fi

started=$(date +%s)
resume_log=$(boot_once)
elapsed=$(($(date +%s) - started))

assert_contains "the next boot continued the raise" "$resume_log" \
  "raising counter"
assert_contains "the next boot reached chainload" "$resume_log" \
  "chainloading next stage"
echo "INFO: finishing the raise to ${INTERRUPTED_VERSION} took ${elapsed}s"

swtpm_start "$STATE" tools
version_after_resume=$(slab_version)
swtpm_stop

if [ "$version_after_resume" = "$INTERRUPTED_VERSION" ]; then
  echo "PASS: the counter reached the list version"
else
  echo "FAIL: the counter is at ${version_after_resume}," \
    "not ${INTERRUPTED_VERSION}"
  FAILED=1
fi

exit "$FAILED"
