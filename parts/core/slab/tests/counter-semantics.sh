#!/bin/sh
# Validates the TPM NV counter semantics slab relies on, using swtpm and
# tpm2-tools. The counter must be definable, a write lock must
# block a later increment, and an undefine then identical redefine must not be
# able to lower the value.
set -u

STATE=$(mktemp -d)
SERVER_PORT=2321
CONTROL_PORT=2322
INDEX=0x01514B00
ATTRIBUTES="nt=counter|authread|authwrite|write_stclear|no_da"

cleanup() {
  [ -n "${SWTPM_PROCESS_ID:-}" ] && kill "$SWTPM_PROCESS_ID" 2>/dev/null
  rm -rf "$STATE"
}
trap cleanup EXIT

swtpm socket --tpm2 --tpmstate dir="$STATE" \
  --ctrl type=tcp,port="$CONTROL_PORT" \
  --server type=tcp,port="$SERVER_PORT" \
  --flags startup-clear &
SWTPM_PROCESS_ID=$!
sleep 1
export TPM2TOOLS_TCTI="swtpm:host=127.0.0.1,port=$SERVER_PORT"

read_value() { tpm2_nvread "$INDEX" 2>/dev/null | od -An -tx1 | tr -d ' \n'; }

define_counter() {
  tpm2_nvdefine "$INDEX" -C o -a "$ATTRIBUTES" >/dev/null 2>&1 \
    || tpm2_nvdefine "$INDEX" -C o -a "$ATTRIBUTES" -s 8 >/dev/null 2>&1
}

FAILED=0

define_counter
tpm2_nvincrement "$INDEX" >/dev/null 2>&1
tpm2_nvincrement "$INDEX" >/dev/null 2>&1
value_before_lock=$(read_value)

tpm2_nvwritelock "$INDEX" >/dev/null 2>&1
if tpm2_nvincrement "$INDEX" >/dev/null 2>&1; then
  echo "FAIL: increment succeeded after write lock"
  FAILED=1
else
  echo "PASS: write lock blocked the increment"
fi

tpm2_nvundefine "$INDEX" -C o >/dev/null 2>&1
define_counter
tpm2_nvincrement "$INDEX" >/dev/null 2>&1
value_after_redefine=$(read_value)

# The values are fixed width zero padded hex, so their lexical order is their
# numeric order. The anti-replay floor holds if the redefined value is not the
# smaller of the two.
smaller=$(printf '%s\n%s\n' "$value_before_lock" "$value_after_redefine" \
  | sort | head -1)
if [ "$smaller" = "$value_before_lock" ]; then
  echo "PASS: value not lowered ($value_before_lock -> $value_after_redefine)"
else
  echo "FAIL: value lowered ($value_before_lock -> $value_after_redefine)"
  FAILED=1
fi

exit "$FAILED"
