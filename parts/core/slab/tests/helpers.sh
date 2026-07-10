# Shared helpers for the slab QEMU test harnesses. Source this from a harness
# in this directory. It holds only what every harness repeats: building slab,
# running swtpm, booting QEMU, building the boot disk, and asserting on output.

TESTS_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
SLAB_DIRECTORY="$(cd "$TESTS_DIRECTORY/.." && pwd)"
REPOSITORY_ROOT="$(git -C "$SLAB_DIRECTORY" rev-parse --show-toplevel)"
BINARY_DIRECTORY="$SLAB_DIRECTORY/target/x86_64-unknown-uefi/debug"

OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_CODE_SECURE_BOOT=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd
OVMF_VARIABLES=/usr/share/OVMF/OVMF_VARS_4M.fd

# Fixed FAT identifiers, so a generated next stage configuration can name the
# filesystem it searches for by UUID.
VOLUME_ID=12345678
FILESYSTEM_UUID=1234-5678

# The line the next stage configuration prints once it has run, matched by the
# harnesses. Kept here so the configuration and the assertion share one string.
NEXT_STAGE_MARKER="next stage configuration reached"

# Seconds to wait for a boot. A booting case powers the machine off well before
# this, so it only bites a case where nothing boots.
BOOT_TIMEOUT=90

# Builds the debug slab binary through the Makefile.
build_slab() {
  make -C "$SLAB_DIRECTORY" test-binary
}

# Builds a real GRUB image to serve as the next stage.
#   $1  output path
build_next_stage() {
  sh "$REPOSITORY_ROOT/.aux/create-grub-bootloader" x86_64-efi "$1"
}

# Copies the OVMF variable template into a state directory and enables slab
# debug output, which is silent otherwise.
#   $1  state directory
prepare_variables() {
  cp "$OVMF_VARIABLES" "$1/vars.fd"
  virt-fw-vars -i "$1/vars.fd" --set-true SlabDebug -o "$1/vars.fd"
}

# Starts a fresh swtpm and sets SWTPM_PROCESS_ID. A fresh swtpm on an existing
# state directory is what a reboot does.
#   $1  state directory
swtpm_start() {
  swtpm socket --tpm2 --tpmstate dir="$1" \
    --ctrl type=unixio,path="$1/sock" --flags startup-clear &
  SWTPM_PROCESS_ID=$!
  sleep 1
}

swtpm_stop() {
  [ -n "${SWTPM_PROCESS_ID:-}" ] || return 0
  kill "$SWTPM_PROCESS_ID" 2>/dev/null || true
  wait "$SWTPM_PROCESS_ID" 2>/dev/null || true
}

# Boots slab under QEMU and prints the serial output.
#   $1  state directory holding vars.fd and the swtpm socket
#   $2  boot disk image
#   $3  OVMF code file, optional, defaults to OVMF_CODE
boot_qemu() {
  code_file="${3:-$OVMF_CODE}"
  timeout "$BOOT_TIMEOUT" qemu-system-x86_64 -machine q35,accel=kvm:tcg -m 256 \
    -drive if=pflash,format=raw,readonly=on,file="$code_file" \
    -drive if=pflash,format=raw,file="$1/vars.fd" \
    -drive format=raw,file="$2" \
    -chardev socket,id=chrtpm,path="$1/sock" \
    -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-crb,tpmdev=tpm0 \
    -display none -serial stdio -no-reboot </dev/null 2>&1 | tee "$1/serial.log"
}

# Builds a GPT boot disk and echoes its path. The ESP holds slab as the
# removable loader, the next stage at the next stage path, and a configuration
# that finds its filesystem by UUID, loads the embedded font, prints the
# marker, and halts.
#   $1  slab binary
#   $2  next stage binary
#   $3  work directory to build in
make_boot_disk() {
  esp="$3/esp.img"
  dd if=/dev/zero of="$esp" bs=1M count=96 status=none
  mkfs.vfat -F32 -i "$VOLUME_ID" "$esp" >/dev/null
  mmd -i "$esp" ::/EFI ::/EFI/BOOT ::/EFI/puavo ::/EFI/puavo/grub
  mcopy -i "$esp" "$1" ::/EFI/BOOT/BOOTX64.EFI
  mcopy -i "$esp" "$2" ::/EFI/puavo/grub/grubx64.efi

  configuration="$3/grub.cfg"
  cat > "$configuration" <<EOF
search --no-floppy --fs-uuid --set=root $FILESYSTEM_UUID
loadfont (memdisk)/boot/grub/fonts/unicode.pf2
lsfonts
echo "$NEXT_STAGE_MARKER"
halt
EOF
  mcopy -i "$esp" "$configuration" ::/EFI/puavo/grub/grub.cfg

  disk="$3/disk.img"
  truncate -s 100M "$disk"
  sgdisk -o -n 1:2048:+96M -t 1:ef00 -c 1:ESP "$disk" >/dev/null
  dd if="$esp" of="$disk" bs=512 seek=2048 conv=notrunc status=none
  echo "$disk"
}

# Asserts that a fixed string appears in the given text.
#   $1  description
#   $2  text to search
#   $3  fixed string that must appear
# Sets FAILED to 1 on failure.
assert_contains() {
  if printf '%s' "$2" | grep -aqF "$3"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1 (missing: $3)"
    FAILED=1
  fi
}

# Asserts that a fixed string does not appear in the given text.
#   $1  description
#   $2  text to search
#   $3  fixed string that must not appear
# Sets FAILED to 1 on failure.
assert_absent() {
  if printf '%s' "$2" | grep -aqF "$3"; then
    echo "FAIL: $1 (unexpected: $3)"
    FAILED=1
  else
    echo "PASS: $1"
  fi
}
