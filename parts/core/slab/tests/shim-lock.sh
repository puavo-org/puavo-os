#!/bin/sh
# Slab installs the image verification protocol the next stage calls for
# every image it loads. Under Secure Boot verify must refuse an image not
# signed by a DB certificate, allow a signed image with no version section,
# allow a signed image at its list minimum, and refuse one below the minimum.
set -u

. "$(dirname "$0")/helpers.sh"

build_slab

WORK=$(mktemp -d)
STATE=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "$WORK" "$STATE"; }
trap cleanup EXIT
GUID="d4a2e1c0-1111-2222-3333-444455556666"

# PK, KEK, and two DB certificates, one for slab and one for the next stage.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$WORK/$1.key" \
    -out "$WORK/$1.crt" -subj "/CN=$1/" -days 3650 2>/dev/null
}
generate_key PK
generate_key KEK
generate_key db_slab
generate_key db_grub

build_next_stage "$WORK/grubx64.efi"

virt-fw-vars -i "$OVMF_VARIABLES" -o "$STATE/vars.fd" \
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

# Builds a signed test image the next stage chainloads. Any image works,
# so a copy of slab is reused. The version section goes in before signing,
# because the signature covers it.
#   $1  test image name
#   $2  optional component name for the version section
#   $3  optional component version for the version section
make_test_image() {
  cp "$BINARY_DIRECTORY/slab.efi" "$WORK/$1.unsigned.efi"
  if [ "$#" -ge 3 ]; then
    "$REPOSITORY_ROOT/.aux/add-bootloader-version-section" \
      "$WORK/$1.unsigned.efi" "$2" "$3"
  fi
  sbsign --key "$WORK/db_grub.key" --cert "$WORK/db_grub.crt" \
    --output "$WORK/$1.efi" "$WORK/$1.unsigned.efi" >/dev/null
}
make_test_image unversioned
make_test_image at-minimum grub 1
make_test_image below-minimum grub 0

# An image not signed by any DB certificate. Verify must refuse it through the
# firmware Secure Boot check. This is the only defense for a caller that
# authenticates through the protocol without chainloading.
cp "$BINARY_DIRECTORY/slab.efi" "$WORK/unsigned.efi"

# The configuration chainloads each test image without booting it, so one
# boot covers all three cases. The refusing case comes last, and nothing
# is echoed for it because the chainload must fail.
configuration="$WORK/shim-lock.cfg"
cat > "$configuration" <<EOF
search --no-floppy --fs-uuid --set=root $FILESYSTEM_UUID
if chainloader /EFI/puavo/unversioned.efi; then
  echo "unversioned image loaded"
fi
if chainloader /EFI/puavo/at-minimum.efi; then
  echo "at-minimum image loaded"
fi
if chainloader /EFI/puavo/below-minimum.efi; then
  echo "below-minimum image loaded"
fi
if chainloader /EFI/puavo/unsigned.efi; then
  echo "unsigned image loaded"
fi
halt
EOF

disk=$(make_boot_disk "$WORK/slab.signed.efi" "$WORK/grub.signed.efi" \
  "$WORK" "$configuration" \
  "$WORK/unversioned.efi" "$WORK/at-minimum.efi" "$WORK/below-minimum.efi" \
  "$WORK/unsigned.efi")

swtpm_start "$STATE"
output=$(boot_qemu "$STATE" "$disk" "$OVMF_CODE_SECURE_BOOT")
swtpm_stop

FAILED=0
assert_contains "slab captured the firmware Secure Boot verifier" "$output" \
  "captured firmware Secure Boot verifier"
assert_contains "an image with no version was allowed" "$output" \
  "unversioned image loaded"
assert_contains "an image at the minimum was allowed" "$output" \
  "at-minimum image loaded"
assert_contains "an image below the minimum was refused by slab" "$output" \
  "image version 0 below minimum 1, refusing"
assert_absent "an image below the minimum was not loaded" "$output" \
  "below-minimum image loaded"
assert_contains "an unsigned image was refused by the firmware check" \
  "$output" "image failed Secure Boot verification"
assert_absent "an unsigned image was not loaded" "$output" \
  "unsigned image loaded"
exit "$FAILED"
