class lightdm {
  include desktop::dconf
  include lightdm::background
  require packages

  file {
    [ '/etc/dconf/db/lightdm.d'
    , '/etc/dconf/db/lightdm.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/lightdm.d/lightdm_profile':
      content => template('lightdm/dconf_lightdm_profile'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/lightdm.d/locks/lightdm_locks':
      content => template('lightdm/dconf_lightdm_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/profile/lightdm':
      content => template('lightdm/dconf_profile_lightdm');
  }

  # lightdm also likes language packages
  Package <| title == lightdm
          or title == language-pack-gnome-de
          or title == language-pack-gnome-en
          or title == language-pack-gnome-fi
          or title == language-pack-gnome-sv |>
}
