#!/bin/sh
# Boots slab from a server with Secure Boot on and custom keys, so slab reads
# the next stage over the network.
# The firmware must load a signed next stage and block an unsigned one.
# No disk is attached, so nothing can satisfy the boot from one.
set -u

. "$(dirname "$0")/helpers.sh"

if ! build_slab; then
  echo "FAIL: slab did not build"
  exit 1
fi

WORK=$(mktemp -d)
cleanup() { swtpm_stop; rm -rf "$WORK"; }
trap cleanup EXIT
GUID="d4a2e1c0-1111-2222-3333-444455556666"

# PK, KEK, and two db certificates, one for slab and one for the next stage.
generate_key() {
  openssl req -x509 -newkey rsa:4096 -nodes -keyout "$WORK/$1.key" \
    -out "$WORK/$1.crt" -subj "/CN=$1/" -days 3650 2>/dev/null
}
generate_key PK
generate_key KEK
generate_key db_slab
generate_key db_grub

build_next_stage "$WORK/grubx64.efi"

virt-fw-vars -i "$OVMF_VARIABLES" -o "$WORK/vars.template.fd" \
  --set-pk "$GUID" "$WORK/PK.crt" \
  --add-kek "$GUID" "$WORK/KEK.crt" \
  --add-db "$GUID" "$WORK/db_slab.crt" \
  --add-db "$GUID" "$WORK/db_grub.crt" \
  --set-true SlabDebug \
  --secure-boot >/dev/null

sbsign --key "$WORK/db_slab.key" --cert "$WORK/db_slab.crt" \
  --output "$WORK/slab.signed.efi" "$BINARY_DIRECTORY/slab.efi" >/dev/null
sbsign --key "$WORK/db_grub.key" --cert "$WORK/db_grub.crt" \
  --output "$WORK/grub.signed.efi" "$WORK/grubx64.efi" >/dev/null

# Boots one case from the server and prints the serial output.
# holds slab as the boot file and the next stage where slab asks for it.
#   $1  next stage binary to serve
boot_from_server() {
  state=$(mktemp -d)
  root="$state/tftp"
  mkdir -p "$root/efi64"
  cp "$WORK/slab.signed.efi" "$root/slabx64.efi"
  cp "$1" "$root/efi64/grubx64.efi"
  cp "$WORK/vars.template.fd" "$state/vars.fd"

  acceleration=""
  if [ -w /dev/kvm ]; then
    acceleration="-enable-kvm -cpu host"
  fi

  swtpm_start "$state"
  # shellcheck disable=SC2086
  timeout "$BOOT_TIMEOUT" qemu-system-x86_64 $acceleration \
    -machine q35 -smp 4 -m 4G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE_SECURE_BOOT" \
    -drive if=pflash,format=raw,file="$state/vars.fd" \
    -netdev "user,id=net0,tftp=$root,bootfile=slabx64.efi" \
    -device virtio-net-pci,netdev=net0,bootindex=1 \
    -chardev socket,id=chrtpm,path="$state/sock" \
    -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-crb,tpmdev=tpm0 \
    -display none -serial stdio -no-reboot </dev/null 2>&1
  swtpm_stop
  rm -rf "$state"
}

FAILED=0

signed=$(boot_from_server "$WORK/grub.signed.efi")
echo "$signed"
assert_contains "slab booted from the server" "$signed" "slab: starting"
assert_contains "slab read the next stage from the server" "$signed" \
  "of next stage from the server"
assert_contains "signed next stage reached chainload" "$signed" \
  "chainloading next stage"
assert_absent "signed next stage was not blocked" "$signed" "chainload failed"
assert_contains "signed next stage ran" "$signed" "GNU GRUB"

# The firmware halts on the boot selection screen when nothing boots, so the
# rejection case needs only a short timeout.
BOOT_TIMEOUT=30

unsigned=$(boot_from_server "$WORK/grubx64.efi")
echo "$unsigned"
assert_contains "slab read the unsigned next stage from the server" \
  "$unsigned" "of next stage from the server"
assert_contains "firmware blocked the unsigned next stage from the server" \
  "$unsigned" "chainload failed: ACCESS_DENIED"

# A next stage larger than slab accepts is refused on its size alone, before
# any of it is read.
dd if=/dev/zero of="$WORK/oversized.efi" bs=1M count=65 status=none
oversized=$(boot_from_server "$WORK/oversized.efi")
echo "$oversized"
assert_contains "oversized next stage was refused" "$oversized" \
  "is too large, refusing"
assert_absent "oversized next stage never reached chainload" "$oversized" \
  "chainloading next stage"

# With nothing to serve, the size cannot be asked for either, so this also
# covers reserving the largest allowed buffer.
: > "$WORK/absent.efi"
absent=$(boot_from_server "$WORK/absent.efi")
echo "$absent"
assert_contains "an empty next stage was refused" "$absent" \
  "next stage missing, refusing to continue"

exit "$FAILED"
