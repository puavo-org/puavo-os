#!/bin/bash
# Create test LUKS images for boot vault and primary partition.
set -eu

usage() {
  echo "Usage: $0 <work-directory> <recovery-key>"
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi

# Close the vault if it is open
if [ -f /dev/mapper/vault ]; then
  echo "Closing the previous vault..."
  cryptsetup close vault
  losetup -D
fi

work_directory="$1"
recovery_key="$2"

vault_image="${work_directory}/vault.img"
primary_partition_image="${work_directory}/primary.img"

mkdir -p "${work_directory}"

echo "Creating the vault image..."
truncate -s 64M "$vault_image"
echo -n "${recovery_key}" | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --batch-mode --key-file - "$vault_image"
echo -n "${recovery_key}" | cryptsetup open --key-file - "$vault_image" vault

echo "Formatting the vault image as ext4..."
mkfs.ext4 -q /dev/mapper/vault

echo "Mounting the vault image..."
mkdir -p "${work_directory}/mnt"
mount /dev/mapper/vault "${work_directory}/mnt"

echo "Storing the recovery key in the vault..."
echo -n "${recovery_key}" > "${work_directory}/mnt/recovery.key"

echo "Closing the vault..."
umount "${work_directory}/mnt"
cryptsetup close vault

echo "Creating the primary partition image..."
truncate -s 64M "$primary_partition_image"
echo -n "${recovery_key}" | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --batch-mode --key-file - "$primary_partition_image"

echo "Created: $vault_image $primary_partition_image"
