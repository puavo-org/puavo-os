class bootserver_munin {
  include bootserver_nginx

  file {
    '/etc/cron.d/munin-node-configure-all':
      content => template('bootserver_munin/munin-node-configure-all-cron.d'),
      mode    => 0644,
      require => [ File['/usr/local/sbin/munin-node-configure-all']
                 , Package['munin-node'] ];

    '/etc/munin/munin-node.conf':
      content => template('bootserver_munin/munin-node.conf'),
      mode    => '0644',
      notify  => Service['munin-node'],
      require => Package['munin-node'];

    '/etc/nginx/sites-available/munin':
      content => template('bootserver_munin/nginx_conf'),
      mode    => '0644',
      notify  => Exec['reload nginx'],
      require => [ Package['munin'], Package['munin-node'] ];

    '/usr/local/sbin/munin-node-configure-all':
      content => template('bootserver_munin/munin-node-configure-all'),
      mode    => 0755;
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
