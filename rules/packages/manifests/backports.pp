class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = [ 'broadcom-sta-dkms'
                  , 'r8168-dkms'

                  # lazarus packages
                  , 'lazarus'
                  , 'lazarus-2.2'
                  , 'lazarus-doc-2.2'
                  , 'lazarus-ide'
                  , 'lazarus-ide-2.2'
                  , 'lazarus-ide-gtk2-2.2'
                  , 'lazarus-src-2.2'
                  , 'lcl-2.2'
                  , 'lcl-gtk2-2.2'
                  , 'lcl-nogui-2.2'
                  , 'lcl-units-2.2'
                  , 'lcl-utils-2.2' ]
}
