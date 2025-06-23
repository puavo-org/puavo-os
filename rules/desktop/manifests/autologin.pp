class desktop::autologin {
  include ::puavo_conf

  file {
    '/etc/pam.d/puavo-lightdm-autologin':
      source => 'puppet:///modules/lightdm/etc_pam.d_puavo-lightdm-autologin';
  }

  ::puavo_conf::script {
    'setup_lightdm':
      source => 'puppet:///modules/desktop/setup_lightdm';
  }
}
