#!/bin/bash
# Reset and start swtpm with vtpm-proxy
set -eu

TPM_STATE=/var/lib/swtpm-state

# Clean up previous state
pkill -9 swtpm 2>/dev/null || true
rm -rf "$TPM_STATE" /dev/tpm0 /dev/tpmrm0
mkdir -p "$TPM_STATE"

# Start swtpm with vtpm-proxy
swtpm chardev --vtpm-proxy --tpm2 --tpmstate dir="$TPM_STATE" &

# Wait for TPM device to appear for up to 5 seconds
for _ in $(seq 1 50); do
    for tpm_device in /dev/tpm[0-9]*; do
        [ -c "$tpm_device" ] || continue
        # Link the device to /dev/tpm0 if it is a different device
        [ "$tpm_device" = /dev/tpm0 ] || {
            tpmrm_device="${tpm_device/tpm/tpmrm}"
            ln -sf "$tpm_device" /dev/tpm0
            ln -sf "$tpmrm_device" /dev/tpmrm0
        }
        exit 0
    done
    sleep 0.1
done

echo "TPM device not found" >&2
exit 1
