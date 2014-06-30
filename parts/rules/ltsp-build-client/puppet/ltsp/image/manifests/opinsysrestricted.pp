class image::opinsysrestricted {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include citrix,
		  crash_reporting,
		  desktop,
		  disable_accounts_service,
		  disable_geoclue,
		  disable_gnome_keyring_autostart,
		  ebeam,
		  firefox,
		  google-earth-stable,
		  google_talkplugin,
		  graphics_drivers,
		  image::bundle::basic,
		  kaffeine,
		  keyutils,
		  libreoffice,
		  ltspimage_java,
		  ltspimage_kdump,
		  ltspimage_opinsys_desktop,
		  ltspimage_plymouth_theme,
		  mimio,
		  network_manager,
		  open-sankore,
		  packages::opinsysrestricted,
		  primus,
		  promethean,
		  puavo_openvpn,
		  puavo_wlan,
		  pycharm,
		  smartboard,
		  tuxpaint,
		  wacom,
		  xexit
        }
      }
    }
  }
}
