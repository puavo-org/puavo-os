class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = [ 'amd64-microcode'
                  , 'b43-fwcutter'
                  , 'broadcom-sta-dkms'
                  , 'firmware-amd-graphics'
                  , 'firmware-atheros'
                  , 'firmware-b43-installer'
                  , 'firmware-b43legacy-installer'
                  , 'firmware-bnx2'
                  , 'firmware-bnx2x'
                  , 'firmware-brcm80211'
                  , 'firmware-cavium'
                  , 'firmware-intel-sound'
                  , 'firmware-intelwimax'
                  , 'firmware-ipw2x00'
                  , 'firmware-ivtv'
                  , 'firmware-iwlwifi'
                  , 'firmware-libertas'
                  , 'firmware-linux'
                  , 'firmware-linux-free'
                  , 'firmware-linux-nonfree'
                  , 'firmware-misc-nonfree'
                  , 'firmware-myricom'
                  , 'firmware-netronome'
                  , 'firmware-netxen'
                  , 'firmware-qcom-media'
                  , 'firmware-qcom-soc'
                  , 'firmware-qlogic'
                  , 'firmware-ralink'
                  , 'firmware-realtek'
                  , 'firmware-samsung'
                  , 'firmware-siano'
                  , 'firmware-ti-connectivity'
                  , 'firmware-zd1211'
                  , 'intel-microcode'
                  , 'iucode-tool'

                  , 'wireless-regdb'    # needed by current kernel,
                                        # and this is needed by puavo-wlanap

                  , 'musescore3'
                  , 'musescore3-common'
                  , 'musescore-general-soundfont' ]
}
