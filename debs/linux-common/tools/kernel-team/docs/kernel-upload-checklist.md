# Linux kernel upload checklist

Things to remember when updating the Linux kernel in any suite.  This
is intentionally kept outside of any source package as it applies to
multiple suites.

1. [< 6.6] ABI maintenance:
   * If there are important changes under `scripts/` or `tools/`, and
     out-of-tree modules should be rebuilt using the new tools, then
     an ABI bump will be needed to ensure this happens.
   * If the upload includes an ABI bump, the `debian/abi` directory
     and all patches in `debian/patches/debian/abi` should have been
     deleted.
   * Otherwise, if this is the upload after an ABI bump, the
     `debian/abi` directory should be populated using
     `debian/bin/abiupdate.py`.

1. [< 5.16] Run the coding style tests and fix any failures:

        export AUTOPKGTEST_TMP="$(mktemp -d)"
        debian/tests/python

1. Make sure that no stale generated files are present:

        git clean -d -f -x debian

   If you aren't using a git checkout for some reason, instead run:

        debian/rules maintainerclean
        debian/rules orig

1. Build the source package, in the target release:
   * At least `debhelper`, `kernel-wedge`, and `python3` must be
     installed.
   * [6.1+] `python3-jinja2` must also be installed.
   * Run:

            debian/rules debian/control
            dpkg-buildpackage -uc -us -S -d

     - [*-backports] Add a `-v` option, specifying the last version
       uploaded to the backports suite.

1. Build the binary packages, in the target release.  Check for
   warnings in the build log, using `scripts/filter-build-log` from
   this repository to filter out warnings that can be ignored.  There
   will still be some warnings and you might need to compare with
   previous builds to see if these are regressions.

1. Test at least one kernel flavour.  Sadly we don't have automated
   tests, but you should do whatever functional testing you can and
   consider asking other team members and contributors to test
   before uploading to the archive.

   The need for pre-upload testing is highest for uploads to security
   suites, as these will be installed by a large number of users
   immediately, and lowest for uploads to experimental.

1. Upload the source package only.  dak is configured to not require
   binaries for linux even if NEW processing is required.

1. If the upload includes an ABI bump (this includes all
   non-experimental uploads of 6.6 onward):
   * [*-security] Handling of NEW packages in security suites
     is awkward.  You may need to directly request the attention of
     the FTP team.
   * [4.19] The linux-latest source package also needs to be updated.
     Wait until after linux and linux-signed-* have been built.
