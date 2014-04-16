class image::opinsys_desktop {
  file { "/tmp/facts.yaml":
    content => inline_template("<%= scope.to_hash.reject { |k,v| !( k.is_a?(String) && v.is_a?(String) ) }.to_yaml %>"),
  }

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
		  graphics_drivers,
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
		  pycharm,
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
