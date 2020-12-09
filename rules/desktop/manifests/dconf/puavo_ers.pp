class desktop::dconf::puavo_ers {
  include ::desktop::dconf

  file {
    '/etc/dconf/db/puavo-ers.d':
      ensure => directory;

    '/etc/dconf/db/puavo-ers.d/puavo_ers_profile':
      content => template('desktop/dconf_puavo_ers_profile'),
      notify  => Exec['update dconf'];
  }
}
