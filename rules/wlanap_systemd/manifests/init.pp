class wlanap_systemd {
  file {
    '/etc/systemd/network/99-default.link':
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/wlanap_systemd/99-default.link';
  }
}
