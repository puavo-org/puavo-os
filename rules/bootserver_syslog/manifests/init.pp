class bootserver_syslog {
  file {
    # Rotate logs every hour, daily is not quite good enough in case there are
    # misbehaving hosts.
    '/etc/cron.hourly/logrotate':
      ensure => link,
      target => '/etc/cron.daily/logrotate';

    '/etc/logrotate.d/hosts':
      content => template('bootserver_syslog/hosts.logrotate'),
      mode    => 0644;

    '/etc/rsyslog.conf':
      content => template('bootserver_syslog/rsyslog.conf'),
      mode    => '0644',
      notify  => Service['rsyslog'];

    '/var/log/hosts':
      ensure => directory,
      group  => adm,
      mode   => '0750',
      owner  => syslog;
  }

  service {
    'rsyslog':
      enable  => 'true',
      ensure  => 'running';
  }
}
