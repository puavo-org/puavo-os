class image::opinsys_unrestricted {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include crash_reporting,
		  desktop,
		  disable_accounts_service,
		  disable_geoclue,
		  disable_gnome_keyring_autostart,
		  firefox,
		  graphics_drivers,
		  image::bundle::basic,
		  kaffeine,
		  keyutils,
		  libreoffice,
		  ltspimage_kdump,
		  ltspimage_opinsys_desktop,
		  ltspimage_plymouth_theme,
		  network_manager,
		  open-sankore,
		  packages::opinsys_unrestricted,
		  puavo_openvpn,
		  puavo_wlan,
		  pycharm,
		  tuxpaint,
		  wacom,
		  xexit
        }
      }
    }
  }
}
