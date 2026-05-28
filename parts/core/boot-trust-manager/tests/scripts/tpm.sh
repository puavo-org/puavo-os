#!/bin/bash
# Reset and start swtpm with vtpm-proxy
set -eu

TPM_STATE=/var/lib/swtpm-state

# Stop swtpm and reset its state
pkill -9 swtpm 2>/dev/null || true
sleep 1
[ -L /dev/tpm0 ] && rm -f /dev/tpm0
[ -L /dev/tpmrm0 ] && rm -f /dev/tpmrm0
rm -rf "$TPM_STATE"
mkdir -p "$TPM_STATE"

# Start swtpm with vtpm-proxy
swtpm chardev --vtpm-proxy --tpm2 --tpmstate dir="$TPM_STATE" &

# Wait for TPM device to appear for up to 5 seconds
for _ in $(seq 1 50); do
    for tpm_device in /dev/tpm[0-9]*; do
        tpmrm_device="${tpm_device/tpm/tpmrm}"
        [ -c "$tpm_device" ] && [ -c "$tpmrm_device" ] || continue

        # Link the device to /dev/tpm0 if it is a different device
        [ "$tpm_device" != /dev/tpm0 ] && \
          ln -sf "$tpm_device" /dev/tpm0
        [ "$tpmrm_device" != /dev/tpmrm0 ] && \
          ln -sf "$tpmrm_device" /dev/tpmrm0

        # Configure max tries, recovery time and lockout recovery time to five minutes
        tpm2_dictionarylockout --setup-parameters \
            --max-tries=8 --recovery-time=300 --lockout-recovery-time=300 --auth=''
        exit 0
    done
    sleep 0.1
done

echo "TPM device not found" >&2
exit 1
