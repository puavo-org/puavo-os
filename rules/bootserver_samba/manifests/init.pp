class bootserver_samba {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/pam.d/samba':
      source => 'puppet:///modules/bootserver_samba/etc_pam.d_samba';
  }

  ::puavo_conf::script {
    'setup_samba':
      source => 'puppet:///modules/bootserver_samba/setup_samba';
  }

  Package <| title == samba or title == winbind |>
}
