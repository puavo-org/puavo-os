#!/bin/sh

set -ex

BUILDDIR=${BUILDDIR:-debian/build/deb}
BACKENDS=${BACKENDS:-x11}

FUZZY_GSK_COMPARE=${FUZZY_GSK_COMPARE:-}
IGNORE_GSK_COMPARE=${IGNORE_GSK_COMPARE:-}
XFAIL_GSK_COMPARE=${XFAIL_GSK_COMPARE:-}

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

    for reftest in $FUZZY_GSK_COMPARE $IGNORE_GSK_COMPARE; do
        rm -f "testsuite/gsk/compare/$reftest.keyfile"
    done
}

trap 'cleanup' EXIT INT

if [ ! -d "$HOME" ]; then
    export HOME="$test_data/home"
    mkdir -p "$HOME"
fi

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="$test_data/xdg-runtime"
    mkdir -p "$XDG_RUNTIME_DIR"
fi

for reftest in $FUZZY_REFTESTS; do
    cp debian/close-enough.keyfile "testsuite/reftests/$reftest.keyfile"
done

for reftest in $FUZZY_GSK_COMPARE; do
    cp debian/close-enough.keyfile "testsuite/gsk/compare/$reftest.keyfile"
done

for reftest in $IGNORE_REFTESTS; do
    cp debian/ignore.keyfile "testsuite/reftests/$reftest.keyfile"
done

for reftest in $IGNORE_GSK_COMPARE; do
    cp debian/ignore.keyfile "testsuite/gsk/compare/$reftest.keyfile"
done

# So that gsettings can find the (uninstalled) gtk schemas
mkdir -p "$test_data/glib-2.0/schemas/"
cp gtk/org.gtk.* "$test_data/glib-2.0/schemas/"
glib-compile-schemas "$test_data/glib-2.0/schemas/"

for BACKEND in $BACKENDS; do
    # Remove LD_PRELOAD so we don't run with fakeroot, which makes dbus-related tests fail
    env \
        -u LD_PRELOAD \
        GIO_MODULE_DIR=/nonexistent \
        GIO_USE_VFS=local \
        GIO_USE_VOLUME_MONITOR=unix \
        dbus-run-session -- \
            debian/tests/run-with-display "$BACKEND" \
                debian/tests/run-with-locales \
                    --generate de_DE.UTF-8 \
                    --generate en_GB.UTF-8 \
                    --generate en_US.UTF-8 \
                    --generate sv_SE=ISO-8859-1 \
                    -- \
                        dh_auto_test --builddirectory="$BUILDDIR" -- \
                            --setup="$BACKEND" \
                            "$@" \
            || touch "$test_data/tests-failed"

    # Don't base64-encode the image results for tests that upstream
    # expect to fail
    for reftest in $XFAIL_REFTESTS; do
        rm -f "$BUILDDIR/testsuite/reftests/output/$BACKEND/$reftest.diff.png"
    done

    for renderer in cairo gl; do
        for reftest in $XFAIL_GSK_COMPARE; do
            rm -f "$BUILDDIR/testsuite/gsk/compare/$renderer/$BACKEND/$reftest.diff.png"
        done
    done

    if [ -e "$test_data/tests-failed" ]; then
        head -v -n-0 "$BUILDDIR/meson-logs/testlog-$BACKEND.txt"
    fi
done

# Put the rest in the log as base64 since we don't have an
# equivalent of AUTOPKGTEST_ARTIFACTS for buildds
debian/log-reftests.py

if [ -e "$test_data/tests-failed" ]; then
    exit 1
fi
