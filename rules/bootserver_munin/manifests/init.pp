class bootserver_munin {
  include bootserver_nginx

  file {
    '/etc/munin/munin-node.conf':
      content => template('bootserver_munin/munin-node.conf'),
      mode    => 0644,
      notify  => Service['munin-node'],
      require => Package['munin-node'];

    '/etc/nginx/sites-available/munin':
      content => template('bootserver_munin/nginx_conf'),
      mode    => 0644,
      notify  => Exec['reload nginx'],
      require => [ Package['munin'], Package['munin-node'] ];
  }

  bootserver_nginx::enable { 'munin': ; }

  package {
    [ 'munin'
    , 'munin-node' ]:
      ensure => present;
  }

  service {
    'munin-node':
      ensure => running;
  }

}
