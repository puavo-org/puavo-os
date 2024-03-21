class desktop::dconf::exammode {
  include ::desktop::dconf

  file {
    '/etc/dconf/db/puavo-exammode.d':
      ensure => directory;

    '/etc/dconf/db/puavo-exammode.d/puavo_exammode_profile':
      content => template('desktop/dconf_puavo_exammode_profile'),
      notify  => Exec['update dconf'];
  }
}
