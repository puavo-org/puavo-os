class bootserver_firewall {
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

  ::bootserver_firewall::conffile {
    'shorewall.conf':
      ;
  }
}
