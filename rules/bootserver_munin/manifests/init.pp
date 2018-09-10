class bootserver_munin {
  include ::bootserver_helpers
  include ::bootserver_nginx

  define plugin ($wildcard = false) {
    $plugin_name = $title
    $real_plugin_name = $wildcard ? {
      true  => regsubst($plugin_name, '([^_]+)_.+', '\1_'),
      false => $plugin_name,
    }

    file {
      "/etc/munin/plugins/$plugin_name":
        ensure  => link,
        require => Package['munin-node'],
        target  => "/usr/share/munin/plugins/${real_plugin_name}",
    }
  }

  file {
    '/etc/munin/munin-node.conf':
      mode    => '0644',
      require => Package['munin-node'],
      source  => 'puppet:///modules/bootserver_munin/munin-node.conf';

    '/etc/munin/plugin-conf.d/cupsys_pages':
      mode    => '0644',
      require => Package['munin-node'],
      source  => 'puppet:///modules/bootserver_munin/cupsys_pages_conf';

    '/etc/nginx/sites-available/munin':
      mode    => '0644',
      require => [ Package['munin'], Package['munin-node'] ],
      source  => 'puppet:///modules/bootserver_munin/nginx_conf';

    '/usr/share/munin/plugins/puavo-bootserver-clients':
      mode    => '0755',
      require => [ File['/usr/local/bin/puavo-bootserver-list-clients']
                 , Package['munin-node'] ],
      source  => 'puppet:///modules/bootserver_munin/puavo-bootserver-clients';

    '/usr/share/munin/plugins/puavo-wlan':
      mode    => '0755',
      require => Package['munin-node'],
      source  => 'puppet:///modules/bootserver_munin/puavo-wlan';
  }

  ::bootserver_munin::plugin {
    'cupsys_pages':
      require => File['/etc/munin/plugin-conf.d/cupsys_pages'];

    [ 'if_eth0'
    , 'if_eth1'
    , 'if_inet0'
    , 'if_ltsp0'
    , 'if_tap0'
    , 'if_wlan0' ]:
      wildcard => true;

    [ 'puavo-bootserver-clients'
    , 'users' ]:
      ;

    'puavo-wlan':
      require => [ Package['python-numpy'], Package['python-redis'] ];
  }

  ::bootserver_nginx::enable { 'munin': ; }

  Package <| title == 'munin'
          or title == 'munin-node'
          or title == 'python-numpy'
          or title == 'python-redis' |>
}
