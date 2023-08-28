class bootserver_backup {
  include ::bootserver_authorized_keys
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-admin-backup.json':
      source => 'puppet:///modules/bootserver_backup/puavo-admin-backup.json';
  }

  file {
    '/usr/local/sbin/rsync-server-backup-home-state':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_backup/rsync-server-backup-home-state';
  }
}
