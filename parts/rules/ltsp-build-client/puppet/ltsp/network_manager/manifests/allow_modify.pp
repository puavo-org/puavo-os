class network_manager::allow_modify {
  require packages

  file {
    '/etc/polkit-1/localauthority/50-local.d/10.org.freedesktop.networkmanager.allow_modify.pkla':
      content => template('network_manager/10.org.freedesktop.networkmanager.allow_modify.pkla');
  }

  Package <| title == policykit-1 |>
}
