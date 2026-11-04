#!/bin/sh
# Creates a LUKS2 image that is encrypted, has unencrypted data, or has an
# unencrypted keyslot area. cryptsetup refuses to create the last one, so the
# keyslot cipher in the header is replaced the way a tampered disk carries it.
set -eu

usage() {
  echo "Usage: $0 <image> encrypted|null-data|null-keyslot"
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi

image=$1
kind=$2

IMAGE_SIZE=$((32 * 1024 * 1024))
NULL_CIPHER="cipher_null-ecb"
# The keyslot cipher cryptsetup picks, as long as the null cipher name.
KEYSLOT_CIPHER="aes-xts-plain64"

# LUKS2 binary header fields, from the LUKS2 on-disk format.
HEADER_SIZE_OFFSET=8
CHECKSUM_OFFSET=$((0x1c0))
CHECKSUM_FIELD_SIZE=64

format() {
  truncate --size="$IMAGE_SIZE" "$image"
  printf passphrase | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 \
    --pbkdf-force-iterations 1000 --batch-mode --key-file - "$image" "$@"
}

# Replaces the keyslot cipher in the header the way an attacker would.
null_keyslot() {
  header=$(mktemp)

  # The size of one header copy, a big endian number in the binary header.
  header_size=$(od --address-radix=n --skip-bytes="$HEADER_SIZE_OFFSET" \
    --read-bytes=8 --format=u8 --endian=big "$image" | tr --delete ' ')

  # The image starts with two copies of the header, and cryptsetup checks
  # both, so each is edited the same way.
  for copy in 0 1; do
    dd if="$image" of="$header" bs="$header_size" skip="$copy" count=1 \
      status=none

    # The header is binary, so sed reads it as NUL separated records. The
    # JSON metadata is one record and lists the keyslots before the data
    # segment, so the first match is the keyslot cipher.
    sed --null-data --in-place "s/${KEYSLOT_CIPHER}/${NULL_CIPHER}/" "$header"

    # The checksum is the SHA-256 of the copy with its checksum field zeroed,
    # stored as binary in that field.
    dd if=/dev/zero of="$header" bs=1 seek="$CHECKSUM_OFFSET" \
      count="$CHECKSUM_FIELD_SIZE" conv=notrunc status=none
    sha256sum "$header" | cut --delimiter=' ' --fields=1 | tr a-f A-F \
      | basenc --base16 --decode \
      | dd of="$header" bs=1 seek="$CHECKSUM_OFFSET" conv=notrunc status=none

    dd if="$header" of="$image" bs="$header_size" seek="$copy" conv=notrunc \
      status=none
  done

  rm --force "${header:?}"
}

case "$kind" in
  encrypted)
    format
    ;;
  null-data)
    format --cipher "$NULL_CIPHER"
    ;;
  null-keyslot)
    format
    null_keyslot
    ;;
  *)
    usage
    ;;
esac
