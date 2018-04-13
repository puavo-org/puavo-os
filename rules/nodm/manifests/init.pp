class nodm {
  # nodm configuration file for infotv sessions
  file {
    '/etc/default/nodm':
      source => 'puppet:///modules/nodm/nodm',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
  }
}
