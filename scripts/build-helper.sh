#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) Opinsys Oy 2026

set -euo pipefail

readonly workspace=/workspace
readonly builds_dir=/home
readonly output_dir=${OUTPUT_DIR:-/output}

if ((EUID == 0)); then
  workspace_uid=$(stat -c %u "${workspace}")
  workspace_gid=$(stat -c %g "${workspace}")

  install -d -m 0755 -o "${workspace_uid}" -g "${workspace_gid}" \
    "${output_dir}"

  if ((workspace_uid != 0)); then
    if ! getent group "${workspace_gid}" >/dev/null; then
      groupadd --gid "${workspace_gid}" puavo-builder
    fi
    if ! getent passwd "${workspace_uid}" >/dev/null; then
      useradd \
        --uid "${workspace_uid}" \
        --gid "${workspace_gid}" \
        --home-dir "${HOME}" \
        --no-create-home \
        --no-log-init \
        --shell /bin/bash \
        puavo-builder
    fi
    printf 'puavo-builder ALL=(ALL) NOPASSWD: ALL\n' \
      > /etc/sudoers.d/puavo-builder
    chmod 0440 /etc/sudoers.d/puavo-builder
    exec gosu "${workspace_uid}:${workspace_gid}" "$0" "$@"
  fi
fi

cd "${workspace}"

# parts/pkg/packages is a git submodule (puavo-os-pkg).  An empty
# checkout makes "make -C pkg/packages all" fail late in rootfs-update.
if [ ! -f parts/pkg/packages/Makefile ]; then
  echo "error: git submodule parts/pkg/packages is not checked out" >&2
  echo "hint: run 'git submodule update --init --recursive'" >&2
  exit 1
fi

IFS=, read -r -a image_classes <<< "${IMAGE_CLASSES:-allinone}"
for image_class in "${image_classes[@]}"; do
  if [[ ! "${image_class}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
    echo "error: invalid image class name: ${image_class}" >&2
    exit 1
  fi
done

read -r -a make_targets <<< \
  "${TARGETS:-rootfs-debootstrap rootfs-update rootfs-image}"

make_args=()
if [ -n "${TARGET_ARCH:-}" ]; then
  make_args+=(target_arch="${TARGET_ARCH}")
fi
if [ -n "${DEBOOTSTRAP_MIRROR:-}" ]; then
  make_args+=(debootstrap_mirror="${DEBOOTSTRAP_MIRROR}")
fi

release_name=${RELEASE_NAME:-}
if [ -z "${release_name}" ]; then
  release_name="container-$(git -C "${workspace}" describe \
    --always --dirty 2>/dev/null || date -u +%Y%m%d%H%M%S)"
fi
make_args+=(release_name="${release_name}")

rootfs_base=${PUAVO_ROOTFS:-${builds_dir}/imagebuilds}

# The build directory may live on a volume mounted over /home, in which
# case the marker file installed by the image is hidden.  Make sure that
# "make" does not try to run "setup-buildhost" (which expects systemd).
sudo mkdir -p "${rootfs_base}"
sudo touch "${rootfs_base}/.is_puavo_buildhost"

for image_class in "${image_classes[@]}"; do
  rootfs_dir="${rootfs_base}/${image_class}"

  if [ -z "${TARGETS:-}" ] &&
     { [ -e "${rootfs_dir}" ] || [ -e "${rootfs_dir}.tmp" ]; }; then
    if [ "${REUSE_ROOTFS:-0}" = 1 ]; then
      echo "reusing existing rootfs ${rootfs_dir}"
      make_targets=(rootfs-update rootfs-image)
    else
      echo "removing existing rootfs ${rootfs_dir}"
      # Detach leftover /proc bind mounts (installed by the chroot
      # wrapper for Rosetta) so that removal does not hit EBUSY.
      sudo umount -l "${rootfs_dir}/proc" "${rootfs_dir}.tmp/proc" \
        2>/dev/null || true
      sudo rm -rf -- "${rootfs_dir}" "${rootfs_dir}.tmp"
    fi
  fi

  # Bind-mount /proc into an existing rootfs so that Rosetta-translated
  # binaries can resolve /proc/self/exe after "unshare --root".  The
  # chroot wrapper does this during debootstrap; reuse and custom TARGETS
  # skip that path and need the mount here.
  for procdir in "${rootfs_dir}/proc" "${rootfs_dir}.tmp/proc"; do
    if [ -d "${procdir}" ] && ! mountpoint -q "${procdir}" 2>/dev/null; then
      sudo mount --bind /proc "${procdir}" 2>/dev/null || true
    fi
  done

  make "${make_targets[@]}" "${make_args[@]}" \
    image_class="${image_class}"
done

images_dir=${PUAVO_IMAGES:-${builds_dir}/puavo-os-images}
if [ -d "${images_dir}" ]; then
  install -d "${output_dir}"
  rsync --archive "${images_dir}/" "${output_dir}/"
fi
