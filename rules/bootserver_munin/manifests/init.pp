class bootserver_munin {
  include bootserver_nginx

  file {
    '/etc/munin/munin-node.conf':
      content => template('bootserver_munin/munin-node.conf'),
      mode    => '0644',
      notify  => Service['munin-node'],
      require => Package['munin-node'];

    '/etc/munin/plugins/puavo-wlan-elements':
      ensure  => link,
      notify  => Service['munin-node'],
      require => Package['puavo-wlancontroller-munin-plugin'],
      target  => '/usr/share/munin/plugins/puavo-wlan-elements';
    
    '/etc/munin/plugins/puavo-wlan-traffic':
      ensure  => link,
      notify  => Service['munin-node'],
      require => Package['puavo-wlancontroller-munin-plugin'],
      target  => '/usr/share/munin/plugins/puavo-wlan-traffic';
    
    '/etc/nginx/sites-available/munin':
      content => template('bootserver_munin/nginx_conf'),
      mode    => '0644',
      notify  => Exec['reload nginx'],
      require => [ Package['munin'], Package['munin-node'] ];
  }

  bootserver_nginx::enable { 'munin': ; }

  package {
    [ 'munin'
    , 'munin-node'
    , 'puavo-wlancontroller-munin-plugin' ]:
      ensure => present;
  }

  service {
    'munin-node':
      ensure  => running,
      require => Package['munin-node'];
  }

  tidy {
    '/etc/munin/plugins':
      matches => [ 'if_err_tap*', 'if_tap*' ],
      notify  => Service['munin-node'],
      recurse => true;
  }
}
