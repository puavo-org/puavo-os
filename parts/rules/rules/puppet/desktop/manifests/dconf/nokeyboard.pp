class desktop::dconf::nokeyboard {
  include desktop::dconf

  file {
    [ '/etc/dconf/db/nokeyboard.d'
    , '/etc/dconf/db/nokeyboard.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/nokeyboard.d/locks/nokeyboard_locks':
      content => template('desktop/dconf_nokeyboard_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/nokeyboard.d/nokeyboard_profile':
      content => template('desktop/dconf_nokeyboard_profile'),
      notify  => Exec['update dconf'];
  }
}
