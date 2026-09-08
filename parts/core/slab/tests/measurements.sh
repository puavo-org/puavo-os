#!/bin/sh
# Records TPM event log during boot. Used for generating test data.
#
# Boots slab under Secure Boot with generated keys and the measurements binary
# as the next stage, then writes what it printed to a capture directory.
#
#   $1  capture directory, a temporary one when absent
set -u

. "$(dirname "$0")/helpers.sh"

CAPTURE="${1:-$(mktemp -d)}"
GUID="d4a2e1c0-1111-2222-3333-444455556666"

build_slab
make -C "${SLAB_DIRECTORY}" measurements

WORK=$(mktemp -d)
STATE=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "${WORK}" "${STATE}"; }
trap cleanup EXIT

# Slab and the next stage are signed with different db certificates.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "${WORK}/$1.key" \
    -out "${WORK}/$1.crt" -subj "/CN=$2/" -days 3650 2>/dev/null
}
generate_key PK "Capture PK"
generate_key KEK "Capture KEK"
generate_key db_slab "Capture Slab"
generate_key db_next_stage "Capture Next Stage"

virt-fw-vars -i "${OVMF_VARIABLES}" -o "${STATE}/vars.fd" \
  --set-pk "${GUID}" "${WORK}/PK.crt" \
  --add-kek "${GUID}" "${WORK}/KEK.crt" \
  --add-db "${GUID}" "${WORK}/db_slab.crt" \
  --add-db "${GUID}" "${WORK}/db_next_stage.crt" \
  --set-true SlabDebug \
  --secure-boot >/dev/null

# Slab refuses a next stage without a version section.
cp "${BINARY_DIRECTORY}/measurements.efi" "${WORK}/measurements.efi"
"${REPOSITORY_ROOT}/.aux/add-bootloader-version-section" \
  "${WORK}/measurements.efi" measurements 1

sbsign --key "${WORK}/db_slab.key" --cert "${WORK}/db_slab.crt" \
  --output "${WORK}/slab.signed.efi" "${BINARY_DIRECTORY}/slab.efi" >/dev/null
sbsign --key "${WORK}/db_next_stage.key" --cert "${WORK}/db_next_stage.crt" \
  --output "${WORK}/measurements.signed.efi" \
  "${WORK}/measurements.efi" >/dev/null

disk=$(make_boot_disk "${WORK}/slab.signed.efi" \
  "${WORK}/measurements.signed.efi" "${WORK}")

swtpm_start "${STATE}"
output=$(boot_qemu "${STATE}" "${disk}" "${OVMF_CODE_SECURE_BOOT}")
swtpm_stop

mkdir -p "${CAPTURE}"

# The console output has CRLF line endings and slab's own messages. The
# capture is between the two marker lines.
printf '%s\n' "${output}" | tr -d '\r' \
  | awk '/^measurements complete$/ { exit }
         printing { print }
         /^measurements begin$/ { printing = 1 }' \
  > "${CAPTURE}/measurements"

# The base value the counter started from. Slab prints it once in debug mode,
# and predicting the slab base measurement needs it.
printf '%s\n' "${output}" | tr -d '\r' \
  | sed -n 's/^counter [0-9]*, base \([0-9]*\)$/\1/p' > "${CAPTURE}/base"

cat > "${CAPTURE}/README" <<EOF
The capture holds the boot measurements the tests compare against. Captured
by parts/core/slab/tests/measurements.sh, slab under Secure Boot with keys
generated for the run, then the measurements binary as the next stage.
EOF

echo "${output}"
echo "capture written to ${CAPTURE}"

FAILED=0
assert_contains "slab chainloaded the measurements binary" "${output}" \
  "chainloading next stage"
assert_contains "every measurement was printed" "${output}" \
  "measurements complete"
measurements=$(cat "${CAPTURE}/measurements")
assert_contains "the log carries the variables" "${measurements}" \
  "event pcr 7 type EFI_VARIABLE_DRIVER_CONFIG"
assert_contains "the log carries an authority" "${measurements}" \
  "event pcr 7 type EFI_VARIABLE_AUTHORITY"
if [ -s "${CAPTURE}/base" ]; then
  echo "PASS: the base was recorded"
else
  echo "FAIL: the base was not recorded"
  FAILED=1
fi
exit "${FAILED}"
