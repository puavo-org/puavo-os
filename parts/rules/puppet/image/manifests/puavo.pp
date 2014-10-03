class image::puavo {
  case $operatingsystem {
    'Ubuntu': {
      include crash_reporting,
	      desktop,
	      disable_accounts_service,
	      disable_geoclue,
	      disable_gnome_keyring_autostart,
	      firefox,
	      gnome_terminal,
	      graphics_drivers,
	      image::bundle::basic,
	      kaffeine,
	      keyutils,
	      libreoffice,
	      network_manager,
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
