class image::puavo {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
	'trusty': {
	  include crash_reporting,
		  desktop,
		  disable_geoclue,
		  disable_gnome_keyring_autostart,
		  firefox,
		  graphics_drivers,
		  image::bundle::basic,
		  kaffeine,
		  keyutils,
		  libreoffice,
		  network_manager,
		  open-sankore,
		  packages::puavo,
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
