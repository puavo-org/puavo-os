class image::bundle::desktop {
  case $operatingsystem {
    'Ubuntu': {
      include acroread,
	      crash_reporting,
	      ::desktop,
	      disable_accounts_service,
	      disable_geoclue,
	      disable_gnome_keyring_autostart,
	      firefox,
	      gnome_terminal,
	      graphics_drivers,
	      image::bundle::basic,
	      kaffeine,
	      keyutils,
	      laptop_mode_tools,
	      libreoffice,
	      network_manager,
	      puavo_wlan,
	      pycharm,
	      tuxpaint,
	      wacom,
	      workaround_firefox_local_swf_bug,
	      xexit
    }
  }
}
