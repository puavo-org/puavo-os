class desktop::dconf::disable_suspend {
  include desktop::dconf

  file {
    [ '/etc/dconf/db/disable_suspend.d'
    , '/etc/dconf/db/disable_suspend.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/disable_suspend.d/disable_suspend_profile':
      content => template('desktop/dconf_disable_suspend_profile'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/disable_suspend.d/locks/disable_suspend_locks':
      content => template('desktop/dconf_disable_suspend_locks'),
      notify  => Exec['update dconf'];
  }
}
