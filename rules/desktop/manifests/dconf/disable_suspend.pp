class desktop::dconf::disable_suspend {
  include ::dconf

  file {
    [ '/etc/dconf/db/disable_suspend.d'
    , '/etc/dconf/db/disable_suspend.d/locks' ]:
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf disable_suspend profile':
      content => template('desktop/dconf_disable_suspend_profile'),
      dbname  => 'disable_suspend',
      subpath => 'disable_suspend_profile';

    'dconf disable_suspend locks':
      content => template('desktop/dconf_disable_suspend_locks'),
      dbname  => 'disable_suspend',
      subpath => 'locks/disable_suspend_locks';
  }
}
