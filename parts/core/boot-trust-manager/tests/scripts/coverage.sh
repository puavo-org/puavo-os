#!/bin/bash
set -eu
mode="${1:-summary}"

if ! command -v cargo-llvm-cov &>/dev/null; then
  cargo install cargo-llvm-cov
fi

case "$mode" in
  summary)
    cargo llvm-cov --test main --summary-only -- --test-threads=1
    ;;
  html)
    cargo llvm-cov --test main --html -- --test-threads=1
    ;;
  *)
    echo "invalid mode: $mode"
    exit 1
    ;;
esac
