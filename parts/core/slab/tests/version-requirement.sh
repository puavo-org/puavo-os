#!/bin/sh
# Boots under QEMU with Secure Boot on and two built-in authorities, one that
# requires the images it approves to declare their version and one whose
# settings make it optional. The next stage loads an image without a version
# under each, and an image with a version under the first. Only the image
# without a version under the first authority must be refused.
set -u

. "$(dirname "$0")/helpers.sh"

WORK=$(mktemp --directory)
STATE=$(mktemp --directory)
cleanup() {
  swtpm_stop
  rm --recursive --force "$WORK" "$STATE"
}
trap cleanup EXIT

# The owner of the firmware keys, and the identities of the two authorities.
GUID="d4a2e1c0-1111-2222-3333-444455556666"
REQUIRING_GUID="3b6f0d2a-5c4e-4f71-9a8b-1e2d3c4b5a69"
OPTIONAL_GUID="8e1a7c53-2d9f-4b06-a5c4-6f3e2b1d0c97"

# Printed by GRUB before each load, see its configuration below.
REQUIRED_MARKER="loading without a version under the requiring authority"
OPTIONAL_MARKER="loading without a version under the optional authority"
VERSIONED_MARKER="loading with a version under the requiring authority"

# Firmware keys: PK and KEK to enable Secure Boot, and db certificates for
# slab and for the GRUB it chainloads. The two authority keys are not in db,
# so only slab's built-in authorities can approve what GRUB loads.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$WORK/$1.key" \
    -out "$WORK/$1.crt" -subj "/CN=$1/" -days 3650 2>/dev/null
}
generate_key PK
generate_key KEK
generate_key db_slab
generate_key db_grub
generate_key requiring
generate_key optional

# The verifier authorities slab is built with, laid out like the real ones:
# one directory per authority with its identity and signing keys. The
# requiring authority has no settings, so it gets the default, a required
# version. The optional authority declares the version optional.
mkdir --parents "$WORK/authorities/requiring/keys" \
  "$WORK/authorities/optional/keys"
echo "$REQUIRING_GUID" > "$WORK/authorities/requiring/identity"
cp "$WORK/requiring.crt" "$WORK/authorities/requiring/keys/requiring.pem"
echo "$OPTIONAL_GUID" > "$WORK/authorities/optional/identity"
cp "$WORK/optional.crt" "$WORK/authorities/optional/keys/optional.pem"
echo "version optional" > "$WORK/authorities/optional/settings"

# Converts the authorities into the form the slab build reads, then builds
# slab with them built in.
"$SCRIPTS_DIRECTORY/generate-verifier-authorities" \
  "$WORK/authorities" "$WORK/generated-authorities" || exit 1
slab=$(build_with_verifier "$WORK/generated-authorities" "$WORK/target") \
  || exit 1

# The measurements binary is a small EFI image used as the image GRUB loads.
make -C "$SLAB_DIRECTORY" measurements || exit 1
build_next_stage "$WORK/grubx64.efi"

# Enrolls the firmware keys and turns Secure Boot on.
virt-fw-vars -i "$OVMF_VARIABLES" -o "$STATE/vars.fd" \
  --set-pk "$GUID" "$WORK/PK.crt" \
  --add-kek "$GUID" "$WORK/KEK.crt" \
  --add-db "$GUID" "$WORK/db_slab.crt" \
  --add-db "$GUID" "$WORK/db_grub.crt" \
  --set-true SlabDebug \
  --secure-boot >/dev/null

# The firmware approves slab and GRUB through db.
sbsign --key "$WORK/db_slab.key" --cert "$WORK/db_slab.crt" \
  --output "$WORK/slab.signed.efi" "$slab" >/dev/null
sbsign --key "$WORK/db_grub.key" --cert "$WORK/db_grub.crt" \
  --output "$WORK/grub.signed.efi" "$WORK/grubx64.efi" >/dev/null

# The measurements image declares no version, so a copy gets one.
unversioned="$BINARY_DIRECTORY/measurements.efi"
cp "$unversioned" "$WORK/versioned.efi"
"$SCRIPTS_DIRECTORY/add-bootloader-version-section" \
  "$WORK/versioned.efi" measurements 1

# The three cases: no version under each authority, and a version under the
# requiring one.
sbsign --key "$WORK/requiring.key" --cert "$WORK/requiring.crt" \
  --output "$WORK/required.efi" "$unversioned" >/dev/null
sbsign --key "$WORK/optional.key" --cert "$WORK/optional.crt" \
  --output "$WORK/optional.efi" "$unversioned" >/dev/null
sbsign --key "$WORK/requiring.key" --cert "$WORK/requiring.crt" \
  --output "$WORK/versioned.signed.efi" "$WORK/versioned.efi" >/dev/null

# GRUB prints a marker before loading each image, so the output of each
# attempt can be told apart, and reports whether the load succeeded.
configuration="$WORK/version-requirement.cfg"
cat > "$configuration" <<EOF
search --no-floppy --fs-uuid --set=root $FILESYSTEM_UUID
echo "$REQUIRED_MARKER"
if chainloader /EFI/puavo/required.efi; then
  echo "required image loaded"
fi
echo "$OPTIONAL_MARKER"
if chainloader /EFI/puavo/optional.efi; then
  echo "optional image loaded"
fi
echo "$VERSIONED_MARKER"
if chainloader /EFI/puavo/versioned.signed.efi; then
  echo "versioned image loaded"
fi
halt
EOF

# Boots slab, which chainloads GRUB, which runs the configuration above.
disk=$(make_boot_disk "$WORK/slab.signed.efi" "$WORK/grub.signed.efi" \
  "$WORK" "$configuration" "$WORK/required.efi" "$WORK/optional.efi" \
  "$WORK/versioned.signed.efi")

swtpm_start "$STATE"
output=$(boot_qemu "$STATE" "$disk" "$OVMF_CODE_SECURE_BOOT")
swtpm_stop

# The output of loading each image, from its marker to the next one.
required_log=$(printf '%s\n' "$output" \
  | sed --quiet "/${REQUIRED_MARKER}/,/${OPTIONAL_MARKER}/p")
optional_log=$(printf '%s\n' "$output" \
  | sed --quiet "/${OPTIONAL_MARKER}/,/${VERSIONED_MARKER}/p")
versioned_log=$(printf '%s\n' "$output" \
  | sed --quiet "/${VERSIONED_MARKER}/,\$p")

# Both authorities are built in with their settings, and only the image
# without a version under the requiring authority is refused.
FAILED=0
assert_contains "the requiring authority is built in" "$output" \
  "identity ${REQUIRING_GUID}, keys: 1, issuers: 0, version: required"
assert_contains "the optional authority is built in" "$output" \
  "identity ${OPTIONAL_GUID}, keys: 1, issuers: 0, version: optional"
assert_contains "an image without a version is refused when required" \
  "$required_log" "image declares no version, which its authority requires"
assert_absent "the image without a version was not loaded" "$required_log" \
  "required image loaded"
assert_contains "an image without a version is allowed when optional" \
  "$optional_log" "image declares no version, which its authority allows"
assert_contains "the image without a version was loaded" "$optional_log" \
  "optional image loaded"
assert_contains "an image with a version is allowed when required" \
  "$versioned_log" "image version 1 allowed"
assert_contains "the image with a version was loaded" "$versioned_log" \
  "versioned image loaded"
exit "$FAILED"
