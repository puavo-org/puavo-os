class bootserver_autopoweron {

  file {
    '/etc/cron.d/puavo-autopoweron':
      content => template('bootserver_autopoweron/puavo-autopoweron.cron'),
      mode    => 0644,
      require => File['/etc/init/puavo-autopoweron.conf'];

    '/etc/init/puavo-autopoweron.conf':
      content => template('bootserver_autopoweron/puavo-autopoweron.upstart'),
      mode    => 0644,
      require => File['/usr/local/lib/puavo-autopoweron'];

    '/usr/local/lib/puavo-autopoweron':
      content => template('bootserver_autopoweron/puavo-autopoweron'),
      mode    => 0755,
      require => Package['wakeonlan'];
  }

  package {
    [ 'moreutils'
    , 'wakeonlan' ]:
      ensure => present;
  }
}
