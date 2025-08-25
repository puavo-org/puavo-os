#!/bin/sh
set -eu

if ! command -v podman 2>/dev/null; then
  echo "error: podman is not installed" >&2
  exit 1
fi

sudo podman rm -f openqa >/dev/null 2>&1 || true

mkdir -p ./data/factory
mkdir -p ./data/pqsql
mkdir -p ./images

# NOTE: Adding "-v ./data/pqsql/:/var/lib/pgsql" will make the web UI persistent
sudo podman run --name openqa --device /dev/kvm -p 1080:80 -p 1443:443 --rm -d \
  -v ./data/factory:/var/lib/openqa/share/factory \
  -v ./puavo:/var/lib/openqa/tests/puavo \
  -v ./images:/var/lib/openqa/share/factory/iso \
  registry.opensuse.org/devel/openqa/containers/openqa-single-instance

sudo podman exec --user root openqa /var/lib/openqa/tests/puavo/setup.sh || true

echo
echo "Web UI is available at http://localhost:1080."
echo "Use scripts in /var/lib/openqa/tests/puavo/scripts/schedule/ to run tests."
echo

sudo podman exec -ti openqa /bin/bash
