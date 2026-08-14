#!/bin/sh
# Boots under QEMU with Secure Boot on and a built-in authority that holds
# only an issuer key. An image signed with a certificate that the issuer key
# signed must be accepted, and an image signed with an unrelated key must be
# refused.
set -u

. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/certificates.sh"

WORK=$(mktemp --directory)
STATE=$(mktemp --directory)
cleanup() {
  swtpm_stop
  rm --recursive --force "$WORK" "$STATE"
}
trap cleanup EXIT
GUID="d4a2e1c0-1111-2222-3333-444455556666"
AUTHORITY_GUID="6d1f7a52-0c1e-4b8e-9a3d-2f5b7c9e1a40"
ISSUED_MARKER="loading the issued image"
UNTRUSTED_MARKER="loading the untrusted image"

# PK, KEK, and two db certificates, one for slab and one for the next stage.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$WORK/$1.key" \
    -out "$WORK/$1.crt" -subj "/CN=$1/" -days 3650 2>/dev/null
}
generate_key PK
generate_key KEK
generate_key db_slab
generate_key db_grub

create_issuer "$WORK/issuer"
issue_signing_certificate "$WORK/issuer" "$WORK/issued"
create_untrusted_signer "$WORK/untrusted"

# The bootloader is built with the verifier and the one authority, laid out
# the way the image build lays out the real ones.
mkdir --parents "$WORK/keys/test/issuers"
echo "$AUTHORITY_GUID" > "$WORK/keys/test/identity"
cp "$WORK/issuer.pem" "$WORK/keys/test/issuers/"
"$REPOSITORY_ROOT/.aux/generate-verifier-authorities" \
  "$WORK/keys" "$WORK/authorities" || exit 1

slab=$(build_with_verifier "$WORK/authorities" "$WORK/target") || exit 1

build_next_stage "$WORK/grubx64.efi"

virt-fw-vars -i "$OVMF_VARIABLES" -o "$STATE/vars.fd" \
  --set-pk "$GUID" "$WORK/PK.crt" \
  --add-kek "$GUID" "$WORK/KEK.crt" \
  --add-db "$GUID" "$WORK/db_slab.crt" \
  --add-db "$GUID" "$WORK/db_grub.crt" \
  --set-true SlabDebug \
  --secure-boot >/dev/null

sbsign --key "$WORK/db_slab.key" --cert "$WORK/db_slab.crt" \
  --output "$WORK/slab.signed.efi" "$slab" >/dev/null
sbsign --key "$WORK/db_grub.key" --cert "$WORK/db_grub.crt" \
  --output "$WORK/grub.signed.efi" "$WORK/grubx64.efi" >/dev/null

# Any image works as the one to load, so a copy of the bootloader is reused.
sbsign --key "$WORK/issued.key" --cert "$WORK/issued.pem" \
  --output "$WORK/issued.efi" "$slab" >/dev/null
sbsign --key "$WORK/untrusted.key" --cert "$WORK/untrusted.pem" \
  --output "$WORK/untrusted.efi" "$slab" >/dev/null

configuration="$WORK/issuers.cfg"
cat > "$configuration" <<EOF
search --no-floppy --fs-uuid --set=root $FILESYSTEM_UUID
echo "$ISSUED_MARKER"
if chainloader /EFI/puavo/issued.efi; then
  echo "issued image loaded"
fi
echo "$UNTRUSTED_MARKER"
if chainloader /EFI/puavo/untrusted.efi; then
  echo "untrusted image loaded"
fi
halt
EOF

disk=$(make_boot_disk "$WORK/slab.signed.efi" "$WORK/grub.signed.efi" \
  "$WORK" "$configuration" "$WORK/issued.efi" "$WORK/untrusted.efi")

swtpm_start "$STATE"
output=$(boot_qemu "$STATE" "$disk" "$OVMF_CODE_SECURE_BOOT")
swtpm_stop

# The output of loading each image, from its marker to the next one.
issued_log=$(printf '%s\n' "$output" \
  | sed --quiet "/${ISSUED_MARKER}/,/${UNTRUSTED_MARKER}/p")
untrusted_log=$(printf '%s\n' "$output" \
  | sed --quiet "/${UNTRUSTED_MARKER}/,\$p")

FAILED=0
assert_contains "the bootloader holds the authority with its issuer" "$output" \
  "identity ${AUTHORITY_GUID}, keys: 0, issuers: 1"
assert_contains "the issuer key signed the certificate of the issued image" \
  "$issued_log" "a built-in issuer key issued the certificate"
assert_contains "the issued image was accepted" "$issued_log" \
  "accepted by a key built in here"
assert_contains "the issued image was loaded" "$issued_log" \
  "issued image loaded"
assert_contains "the issuer key did not sign the untrusted certificate" \
  "$untrusted_log" "no built-in issuer key issued the signer certificate"
assert_contains "the untrusted image was refused" "$untrusted_log" \
  "image failed Secure Boot verification"
assert_absent "the untrusted image was not loaded" "$untrusted_log" \
  "untrusted image loaded"
exit "$FAILED"
