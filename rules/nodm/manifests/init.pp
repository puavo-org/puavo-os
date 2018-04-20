class nodm {
  include ::puavo_conf

  # nodm configuration file for infotv sessions
  ::puavo_conf::script {
    'setup_nodm':
      source => 'puppet:///modules/nodm/setup_nodm';
  }
}
