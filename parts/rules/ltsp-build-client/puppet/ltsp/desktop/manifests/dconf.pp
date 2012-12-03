class desktop::dconf {
  include packages

  exec {
    'update dconf':
      command     => '/usr/bin/dconf update',
      refreshonly => true,
      require     => Package['dconf-tools'];
  }

  file {
    [ '/etc/dconf'
    , '/etc/dconf/db'
    , '/etc/dconf/db/puavodesktop.d'
    , '/etc/dconf/db/puavodesktop.d/locks'
    , '/etc/dconf/profile' ]:
      ensure => directory;

    '/etc/dconf/db/puavodesktop.d/locks/lockprofile':
      content => template('desktop/dconf_puavodesktop_profile_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/puavodesktop.d/profile':
      content => template('desktop/dconf_puavodesktop_profile'),
      notify  => Exec['update dconf'],
      require => Package['ubuntu-mono'];

    '/etc/dconf/profile/user':
      content => template('desktop/dconf_profile_user');
  }

  Package <| (title == ubuntu-mono) or (title == dconf-tools) |>
}
