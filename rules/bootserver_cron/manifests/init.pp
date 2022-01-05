class bootserver_cron {
  file {
    '/usr/local/sbin/puavo-fix-homedir-permissions':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_cron/puavo-fix-homedir-permissions';

    '/usr/local/sbin/puavo-gather-printing-statistics':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_cron/puavo-gather-printing-statistics';
  }
}
