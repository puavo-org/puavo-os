class bootserver_ntp {
  file {
    '/etc/ntp.conf':
      content => template('bootserver_ntp/ntp.conf'),
      mode    => 0644,
      notify  => Service['ntp'],
      require => Package['ntp'];
  }
  
  package {
    'ntp':
      ensure => present;
  }

  service {
    'ntp':
      enable  => true,
      ensure  => running,
      require => Package['ntp'];
  }
}
