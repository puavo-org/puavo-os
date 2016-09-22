class packages::backports {
  define for_packages ($packagelist) {
    $filename = $title

    file {
      "/etc/apt/preferences.d/${filename}.pref":
        content =>
          sprintf("%s%s%s",
                  inline_template("Package: <%= @packagelist.join(' ') %>\n"),
                  "Pin: release a=${lsbdistcodename}-backports\n",
                  "Pin-Priority: 995\n");
    }
  }

  if $lsbdistcodename == 'jessie' {
    @::packages::backports::for_packages {
      'cinnamon':
	packagelist => [ 'cinnamon'
		       , 'cinnamon-*'
		       , 'cjs'
		       , 'gir1.2-cinnamondesktop-3.0'
		       , 'gir1.2-cmenu-3.0'
		       , 'gir1.2-meta-muffin-0.0'
		       , 'libcinnamon-*'
		       , 'libcjs0'
		       , 'libmuffin0'
		       , 'libnemo-extension1'
		       , 'muffin'
		       , 'muffin-common'
		       , 'nemo'
		       , 'nemo-data' ];

      'firmware':
	packagelist => [ 'firmware-amd-graphics'
		       , 'firmware-atheros'
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
		       , 'firmware-linux-nonfree'
		       , 'firmware-misc-nonfree'
		       , 'firmware-myricom'
		       , 'firmware-netxen'
		       , 'firmware-qlogic'
		       , 'firmware-realtek'
		       , 'firmware-samsung'
		       , 'firmware-siano'
		       , 'firmware-ti-connectivity' ];

      'libreoffice':
	packagelist => [ 'libreoffice'
		       , 'libreoffice-*'
		       , 'python3-uno'
		       , 'uno-libs3'
		       , 'ure' ];

      'linux-image':
	packagelist => [ 'linux-base', ];
    }
  }
}
