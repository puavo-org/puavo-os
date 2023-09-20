class bootserver_authorized_keys {
  include ::bootserver_backup

  ::puavo_conf::script {
    'setup_authorized_keys':
      require => [ File['/usr/local/sbin/rsync-server-backup-home-state']
                 , ::Puavo_conf::Definition['puavo-admin-backup.json'] ],
      source  => 'puppet:///modules/bootserver_authorized_keys/setup_authorized_keys';
  }
}
