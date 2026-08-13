#!/bin/sh
# Boots slab under QEMU with Secure Boot on and custom keys. Slab and the next
# stage are signed with different db certificates, as the design requires. The
# firmware must load the signed chain, block an unsigned next stage when slab
# loads it, and reject an unsigned slab outright.
set -u

. "$(dirname "$0")/helpers.sh"

build_slab

WORK=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "$WORK"; }
trap cleanup EXIT
GUID="d4a2e1c0-1111-2222-3333-444455556666"

# PK, KEK, and two db certificates, one for slab and one for the next stage.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$WORK/$1.key" \
    -out "$WORK/$1.crt" -subj "/CN=$1/" -days 3650 2>/dev/null
}
generate_key PK
generate_key KEK
generate_key db_slab
generate_key db_grub

build_next_stage "$WORK/grubx64.efi"

virt-fw-vars -i "$OVMF_VARIABLES" -o "$WORK/vars.template.fd" \
  --set-pk "$GUID" "$WORK/PK.crt" \
  --add-kek "$GUID" "$WORK/KEK.crt" \
  --add-db "$GUID" "$WORK/db_slab.crt" \
  --add-db "$GUID" "$WORK/db_grub.crt" \
  --set-true SlabDebug \
  --secure-boot >/dev/null

sbsign --key "$WORK/db_slab.key" --cert "$WORK/db_slab.crt" \
  --output "$WORK/slab.signed.efi" "$BINARY_DIRECTORY/slab.efi" >/dev/null
sbsign --key "$WORK/db_grub.key" --cert "$WORK/db_grub.crt" \
  --output "$WORK/grub.signed.efi" "$WORK/grubx64.efi" >/dev/null

# Boots one case under Secure Boot and prints the serial output.
#   $1  slab binary
#   $2  next stage binary
boot_case() {
  state=$(mktemp -d)
  work="$state/disk"
  mkdir -p "$work"
  cp "$WORK/vars.template.fd" "$state/vars.fd"
  disk=$(make_boot_disk "$1" "$2" "$work")
  swtpm_start "$state"
  boot_qemu "$state" "$disk" "$OVMF_CODE_SECURE_BOOT"
  swtpm_stop
  rm -rf "$state"
}

FAILED=0

positive=$(boot_case "$WORK/slab.signed.efi" "$WORK/grub.signed.efi")
assert_contains "signed chain reached chainload" "$positive" \
  "chainloading next stage"
assert_absent "signed chain was not blocked" "$positive" "chainload failed"

# The firmware halts on the boot selection screen when nothing boots, so the
# rejection cases below need only a short timeout.
BOOT_TIMEOUT=15

unsigned_stage=$(boot_case "$WORK/slab.signed.efi" "$WORK/grubx64.efi")
assert_contains "firmware blocked the unsigned next stage" "$unsigned_stage" \
  "chainload failed: ACCESS_DENIED"

unsigned_slab=$(boot_case "$BINARY_DIRECTORY/slab.efi" "$WORK/grub.signed.efi")
assert_absent "firmware rejected the unsigned slab" "$unsigned_slab" \
  "slab: starting"

exit "$FAILED"
