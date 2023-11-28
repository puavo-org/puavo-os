#!/bin/sh

set -ex

BUILDDIR=${BUILDDIR:-"$(pwd)/debian/build/deb"}

FUZZY_REFTESTS=${FUZZY_REFTESTS:-}
IGNORE_REFTESTS=${IGNORE_REFTESTS:-}
XFAIL_REFTESTS=${XFAIL_REFTESTS:-}

test_data="$(mktemp -d -t debian-test-data-XXXXXXXX)"
mkdir -p "$test_data"

cleanup() {
    rm -rf "$test_data"

    # Avoid incremental builds with -nc leaking settings into the next build
    for reftest in $FUZZY_REFTESTS $IGNORE_REFTESTS; do
        rm -f "testsuite/reftests/$reftest.keyfile"
    done
}

trap 'cleanup' EXIT INT

for reftest in $FUZZY_REFTESTS; do
    cp debian/close-enough.keyfile "testsuite/reftests/$reftest.keyfile"
done

for reftest in $IGNORE_REFTESTS; do
    cp debian/ignore.keyfile "testsuite/reftests/$reftest.keyfile"
done

# So that gsettings can find the (uninstalled) gtk schemas
mkdir -p "$test_data/glib-2.0/schemas/"
cp gtk/org.gtk.* "$test_data/glib-2.0/schemas/"
glib-compile-schemas "$test_data/glib-2.0/schemas/"

for BACKEND in x11; do
    # Remove LD_PRELOAD so we don't run with fakeroot, which makes dbus-related tests fail
    mkdir -p "$BUILDDIR/testsuite/reftests/output"
    env \
        -u LD_PRELOAD \
        GIO_USE_VFS=local \
        GIO_USE_VOLUME_MONITOR=unix \
        dbus-run-session -- \
            debian/tests/run-with-display x11 \
                dh_auto_test --builddirectory="$BUILDDIR" -- \
                    "$@" \
    || touch "$test_data/tests-failed"

    # Don't base64-encode the image results for tests that upstream
    # expect to fail
    for reftest in $XFAIL_REFTESTS; do
        rm -f "$BUILDDIR/testsuite/reftests/output/$reftest.diff.png"
    done
done

# Put the images in the log as base64 since we don't have an
# equivalent of AUTOPKGTEST_ARTIFACTS for buildds
debian/log-reftests.py

if [ -e "$test_data/tests-failed" ]; then
    exit 1
fi
