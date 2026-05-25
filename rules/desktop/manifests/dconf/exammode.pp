class desktop::dconf::exammode {
  include ::dconf

  file {
    [ '/etc/dconf/db/puavo-exammode.d'
    , '/etc/dconf/db/puavo-exammode.d/locks'
    , '/etc/dconf/db/puavo-exammode-devel.d'
    , '/etc/dconf/db/puavo-exammode-devel.d/locks'
    , '/etc/dconf/db/puavo-exammode-strict.d'
    , '/etc/dconf/db/puavo-exammode-strict.d/locks' ]:
      ensure => directory;
  }

  ::dconf::configfile {
    'dconf puavo_exammode locks':
      content => template('desktop/dconf_puavo_exammode_locks'),
      dbname  => 'puavo-exammode',
      subpath => 'locks/puavo_exammode_locks';

    'dconf puavo_exammode profile':
      content => template('desktop/dconf_puavo_exammode_profile'),
      dbname  => 'puavo-exammode',
      subpath => 'puavo_exammode_profile';

    'dconf puavo_exammode_devel locks':
      content => template('desktop/dconf_puavo_exammode_devel_locks'),
      dbname  => 'puavo-exammode-devel',
      subpath => 'locks/puavo_exammode_devel_locks';

    'dconf puavo_exammode_devel profile':
      content => template('desktop/dconf_puavo_exammode_devel_profile'),
      dbname  => 'puavo-exammode-devel',
      subpath => 'puavo_exammode_devel_profile';

    'dconf puavo_exammode_strict locks':
      content => template('desktop/dconf_puavo_exammode_strict_locks'),
      dbname  => 'puavo-exammode-strict',
      subpath => 'locks/puavo_exammode_strict_locks';

    'dconf puavo_exammode_strict profile':
      content => template('desktop/dconf_puavo_exammode_strict_profile'),
      dbname  => 'puavo-exammode-strict',
      subpath => 'puavo_exammode_strict_profile';
  }
}
