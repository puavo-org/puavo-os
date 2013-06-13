class network_manager::allow_modify {
  require packages

  file {
    '/etc/polkit-1/localauthority/50-local.d/10.org.freedesktop.networkmanager.pkla':
      content => template('network_manager/10.org.freedesktop.networkmanager.pkla');
  }

  Package <| title == policykit-1 |>
}
