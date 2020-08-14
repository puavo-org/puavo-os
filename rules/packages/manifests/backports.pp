class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = [ 'amd64-microcode'
                  , 'b43-fwcutter'
                  , 'broadcom-sta-dkms'
                  , 'intel-microcode'
                  , 'iucode-tool'

                  , 'wireless-regdb'    # needed by current kernel,
                                        # and this is needed by puavo-wlanap

                  , 'musescore3'
                  , 'musescore3-common'
                  , 'musescore-general-soundfont' ]
}
