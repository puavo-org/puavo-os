class image::opinsys_desktop {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include apt_ltspbuild_proxy,
  		  autopoweroff,
		  citrix,
		  console,
		  crash_reporting,
		  desktop,
		  disable_geoclue,
		  ebeam,
		  firefox,
		  google-earth-stable,
		  google_talkplugin,
		  # graphics_drivers,	# XXX nvidia is broken right now
		  kaffeine,
		  kernels,
		  keyutils,
		  libreoffice,
		  lightdm,
		  ltspimage_java,
		  ltspimage_lucid_nfs_compatibility,
		  ltspimage_ssh_server,
		  mimio,
		  motd,
		  network_manager,
		  organisation_adm_users,
		  open-sankore,
		  packages::all,
		  packages::sssd_install_workaround,
		  plymouth_theme,
		  primus,
		  puavo_openvpn,
		  puavo-wlan,
		  # pycharm, # XXX not yet on Trusty
		  smartboard,
		  ssh_client,
		  sudo,
		  tuxpaint,
		  udev,
		  use_urandom,
		  wacom,
		  xexit
        }
      }
    }
  }
}
