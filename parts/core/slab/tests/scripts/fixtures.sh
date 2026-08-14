#!/bin/sh

set -eu

# Generates the files the unit tests read: an issuer, a signature made with
# a certificate the issuer signed, an untrusted key, and an authorities
# directory the bootloader is built with.
#   $1  directory to generate into

usage="usage: $(basename "$0") <output-directory>"
output_directory=${1:?$usage}

. "$(dirname "$0")/../certificates.sh"

AUTHORITY_GUID="6d1f7a52-0c1e-4b8e-9a3d-2f5b7c9e1a40"

work_directory=$(mktemp --directory)
cleanup() {
  rm --recursive --force "$work_directory"
}
trap cleanup EXIT

mkdir --parents "$output_directory"

create_issuer "${work_directory}/issuer"
openssl x509 -in "${work_directory}/issuer.pem" -outform DER \
  -out "${output_directory}/issuer-certificate.der"
write_public_key "${work_directory}/issuer.key" \
  "${output_directory}/issuer.der"

# The certificate code reads only the certificates and the signer of a
# signature, so any signed content works.
issue_signing_certificate "${work_directory}/issuer" \
  "${work_directory}/signer"
echo "signed content" > "${work_directory}/content"
openssl cms -sign -binary -md sha256 -outform DER \
  -signer "${work_directory}/signer.pem" \
  -inkey "${work_directory}/signer.key" \
  -in "${work_directory}/content" \
  -out "${output_directory}/signature.pkcs7"

create_untrusted_signer "${work_directory}/untrusted"
write_public_key "${work_directory}/untrusted.key" \
  "${output_directory}/untrusted.der"

authority_directory="${output_directory}/authorities/test"
mkdir --parents "${authority_directory}/issuers"
echo "$AUTHORITY_GUID" > "${authority_directory}/identity"
cp "${output_directory}/issuer.der" "${authority_directory}/issuers/"
