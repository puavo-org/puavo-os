# Linux kernel backport checklist

Things to check when backporting the Linux kernel package.

1. If backporting as an extra kernel package in stable/oldstable:

   * The source package name must be `linux-`*version* where *version*
     is the first two components of the upstream version.
   * `linux-libc-dev` and the unversioned tools packages must not be
     built, since they are already built from the `linux` source
     package.
   * Compiler meta-packages must not be built if `linux` already
     builds packages with the same names.  If the `linux-headers`
     packages in the backport have versioned dependencies on compiler
     meta-packages, those will then need to be satisfiable by
     `linux`'s compiler meta-packages.
   * For `buster` and later releases, it will be necessary to update
     dak's code signing configuration.  Talk to the FTP team about
     this before uploading.

1. Make sure the build-dependencies are available in the older
   release.

   * In a backports suite, `kernel-wedge` may need to be updated.  In
     a stable/oldstable suite, it might be necessary to disable
     building installer udebs instead.
   * Where user-space tools build-depend on packages or versions not
     available in the older release, those might actually be optional.

1. Revert changes that are incompatible with the older release.

   * If there have been kernel configuration changes that resulted in
     adding a Breaks relation against packages or versions in the
     older release, they should be reverted.
   * If there are kernel behaviour changes that resulted in adding a
     Breaks relation, and they are not configurable, consider whether
     it is possible to revert the change with a patch.
