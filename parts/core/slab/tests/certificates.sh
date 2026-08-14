# Creates certificates for the tests: an issuer, a code signing certificate it
# issues, and an untrusted code signing certificate that no known issuer
# issued. Source this file.

CERTIFICATE_KEY_BITS=4096
CERTIFICATE_VALID_DAYS=$((10 * 365))

# Creates a self-signed issuer certificate and its key.
#   $1  path without extension, $1.pem and $1.key are written
create_issuer() {
  openssl req -x509 -newkey "rsa:${CERTIFICATE_KEY_BITS}" -nodes -sha256 \
    -days "$CERTIFICATE_VALID_DAYS" -subj "/CN=$(basename "$1")/" \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,keyCertSign' \
    -keyout "$1.key" -out "$1.pem" 2>/dev/null
}

# Creates a code signing certificate issued by an issuer, and its key.
#   $1  issuer path without extension
#   $2  path without extension, $2.pem and $2.key are written
issue_signing_certificate() {
  openssl req -new -newkey "rsa:${CERTIFICATE_KEY_BITS}" -nodes \
    -subj "/CN=$(basename "$2")/" -keyout "$2.key" -out "$2.csr" 2>/dev/null
  printf 'extendedKeyUsage=codeSigning\n' > "$2.extensions"
  openssl x509 -req -sha256 -days "$CERTIFICATE_VALID_DAYS" -set_serial 1 \
    -in "$2.csr" -CA "$1.pem" -CAkey "$1.key" -extfile "$2.extensions" \
    -out "$2.pem" 2>/dev/null
}

# Creates a self-signed code signing certificate and its key.
#   $1  path without extension, $1.pem and $1.key are written
create_untrusted_signer() {
  openssl req -x509 -newkey "rsa:${CERTIFICATE_KEY_BITS}" -nodes -sha256 \
    -days "$CERTIFICATE_VALID_DAYS" -subj "/CN=$(basename "$1")/" \
    -addext 'extendedKeyUsage=codeSigning' \
    -keyout "$1.key" -out "$1.pem" 2>/dev/null
}

# Writes the public key of a private key in the form a built-in key is stored.
#   $1  private key
#   $2  output file
write_public_key() {
  openssl rsa -in "$1" -RSAPublicKey_out -outform DER -out "$2" 2>/dev/null
}
