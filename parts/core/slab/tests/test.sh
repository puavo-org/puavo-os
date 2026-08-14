#!/bin/sh
set -eu

TESTS_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"

echo "==> unit"
"$TESTS_DIRECTORY/unit.sh"

echo "==> happy path"
"$TESTS_DIRECTORY/happy-path.sh"

echo "==> persistence"
"$TESTS_DIRECTORY/persistence.sh"

echo "==> refusals"
"$TESTS_DIRECTORY/refusals.sh"

echo "==> secure boot"
"$TESTS_DIRECTORY/secure-boot.sh"

echo "==> network next stage"
"$TESTS_DIRECTORY/network-next-stage.sh"

echo "==> shim lock"
"$TESTS_DIRECTORY/shim-lock.sh"

echo "==> issuers"
"$TESTS_DIRECTORY/issuers.sh"

echo "==> measurements"
"$TESTS_DIRECTORY/measurements.sh"

echo "==> previous revocation list"
"$TESTS_DIRECTORY/previous-revocation-list.sh"

echo "==> high list version"
"$TESTS_DIRECTORY/high-list-version.sh"

echo "==> counter semantics"
"$TESTS_DIRECTORY/counter-semantics.sh"
