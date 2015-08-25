class desktop::dconf::nokeyboard {
  include desktop::dconf

  file {
    '/etc/dconf/db/nokeyboard.d':
      ensure => directory;

    '/etc/dconf/db/nokeyboard.d/nokeyboard_profile':
      content => template('desktop/dconf_nokeyboard_profile'),
      notify  => Exec['update dconf'];
  }
}
