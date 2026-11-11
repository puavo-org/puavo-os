#!/bin/sh
# Boots under QEMU with Secure Boot on and two built-in authorities: one
# signs the next stage with its key, the other issued the certificate of the
# image the next stage loads last. That image prints the event log. PCR 14
# must hold one event per authority, in the order they approved, each with
# the authority identity and the certificate that matched.
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
KEY_OWNER_GUID="d4a2e1c0-1111-2222-3333-444455556666"
SIGNING_AUTHORITY_IDENTITY="2f0c6a1e-7b3d-4c59-8e21-5a9d0b4c7e13"
ISSUING_AUTHORITY_IDENTITY="6d1f7a52-0c1e-4b8e-9a3d-2f5b7c9e1a40"
CERTIFICATE_PCR=14

# Prints the bytes of a GUID as hex in the order EFI stores them.
#   $1  GUID
print_guid_as_hex() {
  echo "$1" | tr --delete '-' | sed \
    's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\4\3\2\1\6\5\8\7/'
}

# Prints the EFI_SIGNATURE_DATA of an authority as hex: its identity as the
# owner, then its certificate.
#   $1  GUID
#   $2  DER certificate
print_signature_data_as_hex() {
  echo "$(print_guid_as_hex "$1")$(od --address-radix=n --format=x1 "$2" \
    | tr --delete ' \n')"
}

# PK, KEK, and a db certificate for slab only, so the built-in authorities
# approve every later image.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$WORK/$1.key" \
    -out "$WORK/$1.crt" -subj "/CN=$1/" -days 3650 2>/dev/null
}
generate_key PK
generate_key KEK
generate_key db_slab
generate_key signing

create_issuer "$WORK/issuer"
issue_signing_certificate "$WORK/issuer" "$WORK/issued"

mkdir --parents "$WORK/keys/signing/keys" "$WORK/keys/issuing/issuers"
echo "$SIGNING_AUTHORITY_IDENTITY" > "$WORK/keys/signing/identity"
cp "$WORK/signing.crt" "$WORK/keys/signing/keys/signing.pem"
echo "$ISSUING_AUTHORITY_IDENTITY" > "$WORK/keys/issuing/identity"
cp "$WORK/issuer.pem" "$WORK/keys/issuing/issuers/"
"$REPOSITORY_ROOT/.aux/generate-verifier-authorities" \
  "$WORK/keys" "$WORK/authorities" || exit 1

slab_binary=$(build_with_verifier "$WORK/authorities" "$WORK/target") || exit 1
make -C "$SLAB_DIRECTORY" measurements || exit 1

build_next_stage "$WORK/grubx64.efi"

virt-fw-vars -i "$OVMF_VARIABLES" -o "$STATE/vars.fd" \
  --set-pk "$KEY_OWNER_GUID" "$WORK/PK.crt" \
  --add-kek "$KEY_OWNER_GUID" "$WORK/KEK.crt" \
  --add-db "$KEY_OWNER_GUID" "$WORK/db_slab.crt" \
  --set-true SlabDebug \
  --secure-boot >/dev/null

sbsign --key "$WORK/db_slab.key" --cert "$WORK/db_slab.crt" \
  --output "$WORK/slab.signed.efi" "$slab_binary" >/dev/null
sbsign --key "$WORK/signing.key" --cert "$WORK/signing.crt" \
  --output "$WORK/grub.signed.efi" "$WORK/grubx64.efi" >/dev/null

# A second image the signing authority approves, which must not add an event.
sbsign --key "$WORK/signing.key" --cert "$WORK/signing.crt" \
  --output "$WORK/again.efi" "$BINARY_DIRECTORY/measurements.efi" >/dev/null
sbsign --key "$WORK/issued.key" --cert "$WORK/issued.pem" \
  --output "$WORK/measurements.efi" "$BINARY_DIRECTORY/measurements.efi" \
  >/dev/null

grub_configuration="$WORK/attestation.cfg"
cat > "$grub_configuration" <<EOF
search --no-floppy --fs-uuid --set=root $FILESYSTEM_UUID
chainloader /EFI/puavo/again.efi
chainloader /EFI/puavo/measurements.efi
boot
EOF

boot_disk=$(make_boot_disk "$WORK/slab.signed.efi" "$WORK/grub.signed.efi" \
  "$WORK" "$grub_configuration" "$WORK/again.efi" "$WORK/measurements.efi")

swtpm_start "$STATE"
boot_output=$(boot_qemu "$STATE" "$boot_disk" "$OVMF_CODE_SECURE_BOOT" \
  | tr -d '\r')
swtpm_stop

# The binary event log, printed as hex between two marker lines.
printf '%s\n' "$boot_output" \
  | sed --quiet '/^event log begin$/,/^event log complete$/s/^log //p' \
  | tr --delete '\n' | tr 'a-f' 'A-F' | basenc --base16 --decode \
  > "$WORK/event-log"
echo "event log: $(wc --bytes < "$WORK/event-log") bytes"

FAILED=0
assert_contains "the measurements image ran" "$boot_output" \
  "measurements complete"

if ! tpm2_eventlog "$WORK/event-log" > "$WORK/event-log.yaml"; then
  echo "FAIL: tpm2_eventlog parses the event log"
  exit 1
fi
echo "PASS: tpm2_eventlog parses the event log"

expected_signature_data="$(print_signature_data_as_hex \
  "$SIGNING_AUTHORITY_IDENTITY" "$WORK/authorities/signing/keys/signing.der")
$(print_signature_data_as_hex \
  "$ISSUING_AUTHORITY_IDENTITY" "$WORK/authorities/issuing/issuers/issuer.der")"
recorded_signature_data=$(yq --raw-output \
  ".events[] | select(.PCRIndex == $CERTIFICATE_PCR) | .Event.VariableData" \
  "$WORK/event-log.yaml")
if [ "$recorded_signature_data" = "$expected_signature_data" ]; then
  echo "PASS: each authority recorded once with its certificate, in order"
else
  echo "FAIL: each authority recorded once with its certificate, in order"
  printf 'expected:\n%s\nrecorded:\n%s\n' "$expected_signature_data" \
    "$recorded_signature_data" | cut --characters=1-100
  FAILED=1
fi

exit "$FAILED"
