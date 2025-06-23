class desktop::autologin {
  include ::puavo_conf

  file {
    '/etc/pam.d/lightdm-autologin-puavo':
      source => 'puppet:///modules/lightdm/etc_pam.d_lightdm-autologin-puavo';
  }

  ::puavo_conf::script {
    'setup_lightdm':
      source => 'puppet:///modules/desktop/setup_lightdm';
  }
}
