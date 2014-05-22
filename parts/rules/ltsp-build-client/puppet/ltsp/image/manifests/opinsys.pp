class image::opinsys {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include citrix,
		  crash_reporting,
		  desktop,
		  disable_geoclue,
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
		  ltspimage_plymouth_theme,
		  mimio,
		  network_manager,
		  open-sankore,
		  packages::opinsys,
		  primus,
		  promethean,
		  puavo_openvpn,
		  puavo-wlan,
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
