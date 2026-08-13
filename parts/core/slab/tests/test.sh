#!/bin/sh
set -eu

TESTS_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"

echo "==> happy path"
"$TESTS_DIRECTORY/happy-path.sh"

echo "==> persistence"
"$TESTS_DIRECTORY/persistence.sh"

echo "==> refusals"
"$TESTS_DIRECTORY/refusals.sh"

echo "==> secure boot"
"$TESTS_DIRECTORY/secure-boot.sh"

echo "==> shim lock"
"$TESTS_DIRECTORY/shim-lock.sh"

echo "==> counter semantics"
"$TESTS_DIRECTORY/counter-semantics.sh"
