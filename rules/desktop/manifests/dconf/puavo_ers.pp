class desktop::dconf::puavo_ers {
  include ::dconf

  file {
    '/etc/dconf/db/puavo-ers.d':
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf puavo-ers':
      content => template('desktop/dconf_puavo_ers_profile'),
      dbname  => 'puavo-ers',
      subpath => 'puavo_ers_profile';
  }
}
