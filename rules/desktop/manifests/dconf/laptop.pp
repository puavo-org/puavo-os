class desktop::dconf::laptop {
  include ::dconf

  file {
    '/etc/dconf/db/laptop.d':
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf laptop':
      content => template('desktop/dconf_laptop_profile'),
      dbname  => 'laptop',
      subpath => 'laptop_profile';
  }
}
