class gsconnect::dconf {
  include ::dconf

  file {
    [ '/etc/dconf/db/puavo-gsconnect.d'
    , '/etc/dconf/db/puavo-gsconnect.d/locks' ]:
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf puavo-gsconnect locks':
      content => template('gsconnect/dconf_gsconnect_locks'),
      dbname  => 'puavo-gsconnect',
      subpath => 'locks/gsconnect_locks';

    'dconf puavo-gsconnect profile':
      content => template('gsconnect/dconf_gsconnect_profile'),
      dbname  => 'puavo-gsconnect',
      subpath => 'gsconnect_profile';
  }
}
