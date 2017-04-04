class image::allinone {
  include ::adm::users
  include ::autopoweroff
  include ::chromium
  include ::console
  include ::desktop
  include ::disable_accounts_service
  include ::disable_geoclue
  include ::disable_suspend_by_tag
  include ::disable_suspend_on_halt
  include ::disable_suspend_on_nbd_devices
  include ::disable_unclutter
  include ::fontconfig
  include ::gdm
  include ::gnome_terminal
  include ::image::bundle::basic
  include ::image::bundle::desktop
  include ::kaffeine
  include ::kernels
  include ::keyutils
  include ::ktouch
  include ::network_manager
  include ::packages
  include ::packages::languages::de
  include ::packages::languages::en
  include ::packages::languages::fi
  include ::packages::languages::fr
  include ::packages::languages::sv
  include ::picaxe_udev_rules
  include ::polkit_printers
  include ::plymouth
  include ::ssh_client
  include ::sysctl
  include ::udev
  include ::use_urandom
  include ::wacom
  include ::wlanap

  stage {
    'init':
      before => Stage['pre-main'];

    'pre-main':
      before => Stage['main'];
  }

  class {
    'apt::default_repositories':
      stage => pre-main;
  }

  Package <| tag == 'tag_debian'
          or tag == 'tag_debian_backports'
          or tag == 'tag_kernel'
          or tag == 'tag_puavo'
          or tag == 'tag_ubuntu' |>
}
