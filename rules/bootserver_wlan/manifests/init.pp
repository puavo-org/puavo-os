class bootserver_wlan {
  include bootserver_config

  file {
    '/etc/puavo-wlangw/vtund.conf':
      content => template('bootserver_wlan/vtund.conf'),
      notify  => Service['puavo-wlangw'],
      require => Package['puavo-wlangw'];

    '/usr/sbin/puavo-wlangw-vtun-up':
      mode    => 755,
      content => template('bootserver_wlan/puavo-wlangw-vtun-up'),
      require => Package['puavo-wlangw'];
  }

  package {
    'puavo-wlangw':
      ensure => present;
  }

  service {
    'puavo-wlangw':
      ensure => running;
  }

}
