class lightdm {
  include desktop::dconf
  include lightdm::background
  require packages

  file {
    '/etc/adduser-guest.conf':
      source => 'puppet:///modules/lightdm/adduser-guest.conf';

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

    '/usr/lib/lightdm':
      ensure => directory;

    '/usr/lib/lightdm/guest-session-auto.sh':
      mode   => 0755,
      source => 'puppet:///modules/lightdm/guest-session-auto.sh';

    '/usr/sbin/guest-account':
      mode   => 0755,
      source => 'puppet:///modules/lightdm/guest-account';
  }

  # lightdm also likes language packages
  Package <| title == lightdm
          or title == language-pack-gnome-de
          or title == language-pack-gnome-en
          or title == language-pack-gnome-fi
          or title == language-pack-gnome-sv |>
}
