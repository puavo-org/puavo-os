#!/bin/bash
# Reset and start swtpm with vtpm-proxy, which creates /dev/tpm0
set -eu

TPM_STATE=/var/lib/swtpm-state

# Kill any existing swtpm
pkill -9 swtpm || true

# Clear state for fresh TPM
rm -rf "$TPM_STATE"
mkdir -p "$TPM_STATE"

# Start swtpm with vtpm-proxy
swtpm chardev --vtpm-proxy --tpm2 --tpmstate dir="$TPM_STATE" &

# Wait for TPM device for 5 seconds at most
for _ in $(seq 1 50); do
    [ -e /dev/tpm0 ] && break
    sleep 0.1
done

[ -e /dev/tpm0 ] || { echo "TPM device not found" >&2; exit 1; }
