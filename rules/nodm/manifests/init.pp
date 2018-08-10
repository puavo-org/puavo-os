class nodm {
  include ::puavo_conf

  file {
    '/etc/pam.d/nodm':
      source => 'puppet:///modules/nodm/etc_pam.d_nodm';
  }

  # nodm configuration file for infotv sessions
  ::puavo_conf::script {
    'setup_nodm':
      source => 'puppet:///modules/nodm/setup_nodm';
  }
}
