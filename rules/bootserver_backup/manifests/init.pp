class bootserver_backup {
  fail('The templates in bootserver_backup need values from puavo-conf')

  file {
    '/root/.ssh':
      ensure => directory,
      mode   => '0700';

    '/root/.ssh/authorized_keys2':
      content => template('bootserver_backup/authorized_keys2'),
      mode    => '0600';

    '/root/run-rdiff-backup-server':
      content => template('bootserver_backup/run-rdiff-backup-server'),
      mode    => '0700';
  }
}
