#!/usr/bin/env bash

set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <full_source_package_version>"
  echo "Example: $0 6.12.38-1~bpo12+1"
  exit 1
fi

echo "foo" >2

DEB_VERSION="$1"
DEB_URL="https://deb.debian.org/debian/pool/main/l/linux/linux_${DEB_VERSION}.debian.tar.xz"
echo "DEB_URL=$DEB_URL" >2

DEB_HASH=$(curl -sSL "$DEB_URL" | sha256sum | awk '{print $1}')
if [ -z "$DEB_HASH" ]; then
  echo "Calculating hash for $DEB_URL failed" >2
  exit 1
fi

ORIG_VERSION=$(echo "$DEB_VERSION" | cut -d'-' -f1)
ORIG_URL="https://deb.debian.org/debian/pool/main/l/linux/linux_${ORIG_VERSION}.orig.tar.xz"
echo "ORIG_URL=$DEB_URL" >2

ORIG_HASH=$(curl -sSL "$ORIG_URL" | sha256sum | awk '{print $1}')
if [ -z "$ORIG_HASH" ]; then
  echo "Calculating hash for $ORIG_URL failed" >2
  exit 1
fi

jq -n \
  --arg name "linux" \
  --arg version "$DEB_VERSION+puavo1+buildonce" \
  --arg orig_hash "$ORIG_HASH" \
  --arg deb_hash "$DEB_HASH" \
  --arg orig_url "$ORIG_URL" \
  --arg deb_url "$DEB_URL" \
  --indent 4 \
  '{
    "name": $name,
    "version": $version,
    "tarballs": {
      "debian": {
        "sha256sum": $deb_hash,
        "url": $deb_url
      },
      "orig": {
        "sha256sum": $orig_hash,
        "url": $orig_url
      }
    }
  }'
