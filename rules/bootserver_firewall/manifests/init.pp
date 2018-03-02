class bootserver_firewall {
  include ::puavo_conf

  define conffile {
    $filename = $title

    file {
      "/etc/shorewall/${filename}":
        content => template("bootserver_firewall/etc_shorewall/${filename}");
    }
  }

  file {
    '/etc/default/shorewall':
      content => template('bootserver_firewall/etc_default_shorewall');

    '/etc/shorewall':
      ensure => directory;
  }

  ::puavo_conf::script {
    'setup_firewall':
      source => 'puppet:///modules/bootserver_firewall/setup_firewall';
  }

  ::bootserver_firewall::conffile {
    [ 'Makefile'
    , 'hosts'
    , 'interfaces'
    , 'masq'
    , 'policy'
    , 'rules'
    , 'shorewall.conf'
    , 'tunnels'
    , 'zones' ]:
      ;
  }
}
