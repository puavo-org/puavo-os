class lightdm {
  include desktop::dconf::puavodesktop,
          lightdm::login_prompt_as_default
  require packages

  file {
    '/etc/dconf/db/puavodesktop.d/lightdm_profile':
      content => template('lightdm/dconf_lightdm_profile'),
      notify  => Exec['update dconf'];
  }

  # lightdm also likes language packages
  Package <| title == lightdm
          or title == language-pack-gnome-en
          or title == language-pack-gnome-fi
          or title == language-pack-gnome-sv |>
}
