class bootserver_syslog {

  file {
    '/etc/rsyslog.conf':
      content => template('bootserver_syslog/rsyslog.conf'),
      mode    => 0644,
      notify  => Service['rsyslog'];

    '/var/log/hosts':
      ensure => directory,
      group  => adm,
      mode   => 0750,
      owner  => syslog;
  }

  service {
    'rsyslog':
      enable  => 'true',
      ensure  => 'running';
  }

}
