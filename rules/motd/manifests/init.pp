class motd {
  file {
    '/etc/update-motd.d/20-w':
      mode   => '0755',
      source => 'puppet:///modules/motd/20-w';

    '/etc/update-motd.d/50-host-removed':
      mode   => '0755',
      source => 'puppet:///modules/motd/50-host-removed';

    '/etc/motd':
      content => "";
  }
}
