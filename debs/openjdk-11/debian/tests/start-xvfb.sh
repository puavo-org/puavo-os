#!/bin/bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

if [ -z "${AUTOPKGTEST_TMP+x}" ] || [ -z "${AUTOPKGTEST_ARTIFACTS+x}" ]; then
  echo "Environment variables AUTOPKGTEST_TMP and AUTOPKGTEST_ARTIFACTS must be set" >&2
  exit 1
fi
export XAUTHORITY="${AUTOPKGTEST_TMP}/.Xauthority"
export XDG_CACHE_HOME="${AUTOPKGTEST_TMP}"
export XDG_DATA_HOME="${AUTOPKGTEST_TMP}"
export XDG_CONFIG_HOME="${AUTOPKGTEST_TMP}"
export XDG_RUNTIME_DIR=`mktemp -d`

exec dbus-run-session xvfb-run --server-num=${1:-10} \
  --error-file="${AUTOPKGTEST_ARTIFACTS}/xvfb-run.log" \
  --auth-file=${XAUTHORITY} \
  --server-args="-fbdir ${AUTOPKGTEST_TMP} -pixdepths 8 16 24 32 -extension GLX -screen 0 1600x900x24" \
  xfwm4
