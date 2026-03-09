class abitti2 {
  include ::packages
  include ::puavo_conf

  file {
    [ '/etc/puavo-extra-contents', '/etc/puavo-extra-contents/scripts' ]:
      ensure => directory;

    '/etc/puavo-extra-contents/scripts/Abitti2':
      mode    => '0755',
      require => File['/usr/local/lib/puavo-trigger-abitti2-updates'],
      source  => 'puppet:///modules/abitti2/etc_puavo-extra-contents_scripts_Abitti2';

   '/etc/systemd/system/multi-user.target.wants/puavo-trigger-abitti2-updates.service':
      ensure  => link,
      require => File['/etc/systemd/system/puavo-trigger-abitti2-updates.service'],
      target  => '/etc/systemd/system/puavo-trigger-abitti2-updates.service';

    '/etc/systemd/system/multi-user.target.wants/puavo-abitti2-torrent-updated.service':
      ensure  => link,
      require => File['/etc/systemd/system/puavo-abitti2-torrent-updated.service'],
      target  => '/etc/systemd/system/puavo-abitti2-torrent-updated.service';

    '/etc/systemd/system/puavo-abitti2-torrent-updated.service':
      source => 'puppet:///modules/abitti2/puavo-abitti2-torrent-updated.service';

    '/etc/systemd/system/puavo-abitti2-torrent-updated.socket':
      source => 'puppet:///modules/abitti2/puavo-abitti2-torrent-updated.socket';

    '/etc/systemd/system/puavo-trigger-abitti2-updates.service':
      require => File['/usr/local/lib/puavo-trigger-abitti2-updates'],
      source  => 'puppet:///modules/abitti2/puavo-trigger-abitti2-updates.service';

    '/usr/local/lib/puavo-trigger-abitti2-updates':
      mode    => '0755',
      require => File['/usr/local/sbin/puavo-update-abitti2-image'],
      source  => 'puppet:///modules/abitti2/puavo-trigger-abitti2-updates';

    '/usr/local/sbin/puavo-update-abitti2-image':
      mode    => '0755',
      require => ::Puavo_conf::Definition['puavo-abitti2.json'],
      source  => 'puppet:///modules/abitti2/puavo-update-abitti2-image';
  }

  ::puavo_conf::definition {
    'puavo-abitti2.json':
      source => 'puppet:///modules/abitti2/puavo-abitti2.json';
  }

  ::puavo_conf::hook {
    [ 'puavo.abitti2.mode', 'puavo.abitti2.version', ]:
      require => Puavo_conf::Script['trigger_abitti2_updates'],
      script  => 'trigger_abitti2_updates';
  }

  ::puavo_conf::script {
    'trigger_abitti2_updates':
      source => 'puppet:///modules/abitti2/trigger_abitti2_updates';
  }
}
