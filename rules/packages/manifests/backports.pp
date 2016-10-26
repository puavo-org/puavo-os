class packages::backports {
  define for_packages ($packagelist) {
    $filename = $title

    file {
      "/etc/apt/preferences.d/${filename}.pref":
        content =>
          sprintf("%s%s%s",
                  inline_template("Package: <%= @packagelist.join(' ') %>\n"),
                  "Pin: release a=${debianversioncodename}-backports\n",
                  "Pin-Priority: 995\n");
    }
  }

  if $debianversioncodename == 'jessie' {
    @::packages::backports::for_packages {
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
