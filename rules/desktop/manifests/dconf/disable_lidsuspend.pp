class desktop::dconf::disable_lidsuspend {
  include desktop::dconf

  file {
    [ '/etc/dconf/db/disable_lidsuspend.d'
    , '/etc/dconf/db/disable_lidsuspend.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/disable_lidsuspend.d/disable_lidsuspend_profile':
      content => template('desktop/dconf_disable_lidsuspend_profile'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/disable_lidsuspend.d/locks/disable_lidsuspend_locks':
      content => template('desktop/dconf_disable_lidsuspend_locks'),
      notify  => Exec['update dconf'];
  }
}
