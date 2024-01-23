class nodm {
  include ::puavo_conf

  file {
    '/etc/default/nodm':
      source => 'puppet:///modules/nodm/etc_default_nodm';

    '/etc/pam.d/nodm':
      source => 'puppet:///modules/nodm/etc_pam.d_nodm';

    # We want nodm to be able to co-exist with gdm (for examination mode),
    # remove the /etc/X11/default-display-manager test.
    '/etc/systemd/system/nodm.service.d/override.conf':
      content => "[Service]\nExecStartPre=\n";
  }

  # nodm configuration file for infotv sessions
  ::puavo_conf::script {
    'setup_nodm':
      source => 'puppet:///modules/nodm/setup_nodm';
  }
}
