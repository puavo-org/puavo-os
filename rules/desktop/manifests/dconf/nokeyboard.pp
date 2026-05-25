class desktop::dconf::nokeyboard {
  include ::dconf

  file {
    [ '/etc/dconf/db/nokeyboard.d'
    , '/etc/dconf/db/nokeyboard.d/locks' ]:
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf nokeyboard locks':
      content => template('desktop/dconf_nokeyboard_locks'),
      dbname  => 'nokeyboard',
      subpath => 'locks/nokeyboard_locks';

    'dconf nokeyboard profile':
      content => template('desktop/dconf_nokeyboard_profile'),
      dbname  => 'nokeyboard',
      subpath => 'nokeyboard_profile';
  }
}
