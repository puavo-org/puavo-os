class bootserver_backup {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-admin-backup.json':
      source => 'puppet:///modules/bootserver_backup/puavo-admin-backup.json';
  }

  ::puavo_conf::script {
    'setup_backup':
      require => ::Puavo_conf::Definition['puavo-admin-backup.json'],
      source  => 'puppet:///modules/bootserver_backup/setup_backup';
  }

  file {
    '/usr/local/sbin/rsync-server-backup-home-state':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_backup/rsync-server-backup-home-state';
  }
}
