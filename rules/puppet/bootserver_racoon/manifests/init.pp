class bootserver_racoon {
  file {
    '/etc/racoon/racoon.conf':
      content => template('bootserver_racoon/racoon.conf'),
      mode    => 0644,
      notify  => Service['racoon'];
  }

  package {
    'racoon':
      ensure => present;
  }

  service {
    'racoon':
      enable  => true,
      require => Package['racoon'];
  }
}
