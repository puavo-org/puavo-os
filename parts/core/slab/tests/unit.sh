#!/bin/sh

set -eu

# Runs the unit tests. They build for the machine running them, while the
# bootloader builds for the firmware.

tests_directory="$(cd "$(dirname "$0")" && pwd)"
slab_directory="$(dirname "$tests_directory")"

FIXTURES_DIRECTORY=$(mktemp --directory)
export FIXTURES_DIRECTORY
cleanup() {
  rm --recursive --force "$FIXTURES_DIRECTORY"
}
trap cleanup EXIT

"${tests_directory}/scripts/fixtures.sh" "$FIXTURES_DIRECTORY"
SLAB_VERIFIER_KEYS="${FIXTURES_DIRECTORY}/authorities" cargo test \
  --manifest-path "${slab_directory}/Cargo.toml" --bin slab --features verifier
