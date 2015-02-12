class bootserver_munin {
  include bootserver_nginx

  file {
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

}
