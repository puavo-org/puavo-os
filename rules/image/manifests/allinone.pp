class image::allinone {
  include ::adm::users,
          ::autopoweroff,
          ::chromium,
          ::console,
          ::desktop,
          ::disable_accounts_service,
          ::disable_geoclue,
          ::disable_suspend_by_tag,
          ::disable_suspend_on_halt,
          ::disable_suspend_on_nbd_devices,
          ::disable_unclutter,
          ::fontconfig,
          ::gnome_terminal,
          ::image::bundle::basic,
          ::kaffeine,
          ::kernels,
          ::keyutils,
          ::ktouch,
          ::laptop_mode_tools,
          ::lightdm,
          ::network_manager,
          ::packages,
          ::packages,
          ::packages::languages::de,
          ::packages::languages::en,
          ::packages::languages::fi,
          ::packages::languages::fr,
          ::packages::languages::sv,
          ::picaxe_udev_rules,
          ::plymouth,
          ::ssh_client,
          ::sysctl,
          ::udev,
          ::use_urandom,
          ::wacom

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
          or tag == 'tag_kernel'
          or tag == 'tag_puavo' |>
}
