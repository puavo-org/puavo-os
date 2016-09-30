class apparmor {
  package {
    'apparmor':
      ensure => present;
  }

  service {
    'apparmor':
      enable  => true,
      require => Package['apparmor'];
  }
}
