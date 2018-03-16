class bootserver_samba {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/pam.d/samba':
      source => 'puppet:///modules/bootserver_samba/etc_pam.d_samba');
  }

  ::puavo_conf::script {
    'setup_samba':
      source => 'puppet:///modules/bootserver_samba/setup_samba');
  }

  # XXX this should be done somehow
  # exec {
  #   'fetch cifs.keytab':
  #     command => "/usr/bin/smbpasswd -w '${puavo_ldap_password}' && /usr/sbin/kadmin.local -q 'ktadd -norandkey -k /etc/samba/cifs.keytab cifs/${puavo_hostname}.${puavo_domain}'",
  #     creates => '/etc/samba/cifs.keytab';
  # }

  Package <| title == samba or title == winbind |>
}
