class desktop::dconf::laptop {
  include ::desktop::dconf

  file {
    '/etc/dconf/db/laptop.d':
      ensure => directory;

    '/etc/dconf/db/laptop.d/laptop_profile':
      content => template('desktop/dconf_laptop_profile'),
      notify  => Exec['update dconf'];
  }
}
