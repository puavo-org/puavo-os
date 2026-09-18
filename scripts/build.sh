#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) Opinsys Oy 2026

set -euo pipefail

CONTAINER=${CONTAINER:-docker}
CONTAINER_CPUS=${CONTAINER_CPUS:-8}
CONTAINER_MEMORY=${CONTAINER_MEMORY:-16G}
PLATFORM=${PLATFORM:-linux/amd64}

build_args=(
  --platform "${PLATFORM}"
  --tag puavo-os-builder:latest
)
if [ "$(basename -- "${CONTAINER}")" = container ]; then
  build_args=(
    --cpus "${CONTAINER_CPUS}"
    --memory "${CONTAINER_MEMORY}"
    "${build_args[@]}"
  )
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

for volume in puavo-os-build puavo-os-output; do
  "${CONTAINER}" volume inspect "${volume}" >/dev/null 2>&1 ||
    "${CONTAINER}" volume create "${volume}" >/dev/null
done

"${CONTAINER}" build "${build_args[@]}" .

run_args=(
  --platform "${PLATFORM}"
  --init
  # The build needs mount and unshare; Apple's "container" runtime
  # restricts capabilities by default.  Redundant on docker/podman,
  # which already grant a superset by default.
  --cap-add ALL
  --cpus "${CONTAINER_CPUS}"
  --memory "${CONTAINER_MEMORY}"
  --env OUTPUT_DIR=/output
  --volume "${PWD}:/workspace"
  --volume puavo-os-build:/home
  --volume puavo-os-output:/output
)

if [ "${FOREGROUND:-0}" = 1 ]; then
  run_args+=(--rm)
else
  run_args+=(-d)
fi

for env in \
  DEBOOTSTRAP_MIRROR \
  IMAGE_CLASSES \
  RELEASE_NAME \
  REUSE_ROOTFS \
  TARGET_ARCH \
  TARGETS
do
  if [ -n "${!env:-}" ]; then
    run_args+=(--env "${env}")
  fi
done

"${CONTAINER}" run "${run_args[@]}" puavo-os-builder:latest "$@"
