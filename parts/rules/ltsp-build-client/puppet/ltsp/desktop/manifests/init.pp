class desktop {
  include packages

  exec {
    'update dconf':
      command     => '/usr/bin/dconf update',
      refreshonly => true;
  }

  file {
    [ '/etc/dconf/db/user.d'
    , '/etc/dconf/db/user.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/user.d/locks/locklist':
      content => template('desktop/dconf_user_profile_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/user.d/profile':
      content => template('desktop/dconf_user_profile'),
      notify  => Exec['update dconf'],
      require => Package['ubuntu-mono'];
  }

  Package <| title == ubuntu-mono |>
}
