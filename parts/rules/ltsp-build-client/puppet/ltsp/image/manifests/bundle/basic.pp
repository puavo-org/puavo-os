class image::bundle::basic {
  include apt_ltspbuild_proxy,
	  autopoweroff,
	  console,
	  kernels,
	  lightdm,
	  ltspimage_ssh_server,
	  motd,
	  organisation_adm_users,
	  plymouth_theme,
	  ssh_client,
	  sudo,
	  udev,
	  use_urandom
}
