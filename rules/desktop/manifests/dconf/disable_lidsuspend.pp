class desktop::dconf::disable_lidsuspend {
  include ::dconf

  file {
    [ '/etc/dconf/db/disable_lidsuspend.d'
    , '/etc/dconf/db/disable_lidsuspend.d/locks' ]:
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf disable_lidsuspend profile':
      content => template('desktop/dconf_disable_lidsuspend_profile'),
      dbname  => 'disable_lidsuspend',
      subpath => 'disable_lidsuspend_profile';

    'dconf disable_lidsuspend locks':
      content => template('desktop/dconf_disable_lidsuspend_locks'),
      dbname  => 'disable_lidsuspend',
      subpath => 'locks/disable_lidsuspend_locks';
  }
}
