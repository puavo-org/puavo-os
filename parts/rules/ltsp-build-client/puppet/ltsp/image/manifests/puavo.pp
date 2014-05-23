class image::puavo {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
	'trusty': {
	  include crash_reporting,
		  desktop,
		  disable_geoclue,
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
		  puavo-wlan,
		  pycharm,
		  tuxpaint,
		  wacom,
		  xexit
	}
      }
    }
  }
}
