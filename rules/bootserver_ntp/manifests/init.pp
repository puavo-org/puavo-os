class bootserver_ntp {
  file {
    '/etc/ntp.conf':
      content => template('bootserver_ntp/ntp.conf'),
      mode    => '0644',
      require => Package['ntp'];
  }

  package {
    'ntp':
      ensure => present;
  }
}
