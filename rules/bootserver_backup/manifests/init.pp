class bootserver_backup {
  include ::bootserver_config

  file {
    '/root/.ssh':
      ensure => directory,
      mode   => 700;

    '/root/.ssh/authorized_keys2':
      content => template('bootserver_backup/authorized_keys2'),
      mode    => 600;

    '/root/run-rdiff-backup-server':
      content => template('bootserver_backup/run-rdiff-backup-server'),
      mode    => 700;
  }
}
