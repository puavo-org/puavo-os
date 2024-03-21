class desktop::dconf::exammode {
  include ::desktop::dconf

  file {
    [ '/etc/dconf/db/puavo-exammode.d'
    , '/etc/dconf/db/puavo-exammode.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/puavo-exammode.d/locks/puavo_exammode_locks':
      content => template('desktop/dconf_puavo_exammode_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/puavo-exammode.d/puavo_exammode_profile':
      content => template('desktop/dconf_puavo_exammode_profile'),
      notify  => Exec['update dconf'];
  }
}
