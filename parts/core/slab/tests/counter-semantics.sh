#!/bin/sh
# Validates the TPM NV counter semantics slab relies on, using swtpm and
# tpm2-tools. The counter must be definable, a write lock must
# block a later increment, and an undefine then identical redefine must not be
# able to lower the value.
set -u

. "$(dirname "$0")/helpers.sh"

ATTRIBUTES="nt=counter|authread|authwrite|write_stclear|no_da"

STATE=$(mktemp --directory)
cleanup() {
  swtpm_stop
  rm --recursive --force "$STATE"
}
trap cleanup EXIT

swtpm_start "$STATE" tools

define_counter() {
  tpm2_nvdefine "$COUNTER_INDEX" -C o -a "$ATTRIBUTES" >/dev/null 2>&1 \
    || tpm2_nvdefine "$COUNTER_INDEX" -C o -a "$ATTRIBUTES" -s 8 >/dev/null 2>&1
}

FAILED=0

define_counter
tpm2_nvincrement "$COUNTER_INDEX" >/dev/null 2>&1
tpm2_nvincrement "$COUNTER_INDEX" >/dev/null 2>&1
value_before_lock=$(nv_value "$COUNTER_INDEX")

tpm2_nvwritelock "$COUNTER_INDEX" >/dev/null 2>&1
if tpm2_nvincrement "$COUNTER_INDEX" >/dev/null 2>&1; then
  echo "FAIL: increment succeeded after write lock"
  FAILED=1
else
  echo "PASS: write lock blocked the increment"
fi

tpm2_nvundefine "$COUNTER_INDEX" -C o >/dev/null 2>&1
define_counter
tpm2_nvincrement "$COUNTER_INDEX" >/dev/null 2>&1
value_after_redefine=$(nv_value "$COUNTER_INDEX")

# A redefined counter must not come back lower, or an older revocation list
# would boot again.
if [ "$value_after_redefine" -ge "$value_before_lock" ]; then
  echo "PASS: value not lowered ($value_before_lock -> $value_after_redefine)"
else
  echo "FAIL: value lowered ($value_before_lock -> $value_after_redefine)"
  FAILED=1
fi

exit "$FAILED"
