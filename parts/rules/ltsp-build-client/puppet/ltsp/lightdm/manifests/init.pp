class lightdm {
  include desktop::dconf::puavodesktop,
          packages

  file {
    '/etc/dconf/db/puavodesktop.d/lightdm_profile':
      content => template('lightdm/dconf_lightdm_profile'),
      notify  => Exec['update dconf'];
  }

  Package <| title == lightdm |>
}
