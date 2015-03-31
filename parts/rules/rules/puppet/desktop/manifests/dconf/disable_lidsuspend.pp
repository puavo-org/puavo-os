class desktop::dconf::disable_lidsuspend {
  include desktop::dconf

  file {
    '/etc/dconf/db/disable_lidsuspend.d':
      ensure => directory;

    '/etc/dconf/db/disable_lidsuspend.d/disable_lidsuspend':
      content => template('desktop/dconf_disable_lidsuspend'),
      notify  => Exec['update dconf'];
  }
}
