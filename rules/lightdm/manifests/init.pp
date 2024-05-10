class lightdm {
  include ::puavo_conf

  file {
    '/etc/pam.d/lightdm-autologin':
      source => 'puppet:///modules/lightdm/etc_pam.d_lightdm-autologin';
  }

  # lightdm configuration file for infotv sessions
  ::puavo_conf::script {
    'setup_lightdm':
      source => 'puppet:///modules/lightdm/setup_lightdm';
  }
}
