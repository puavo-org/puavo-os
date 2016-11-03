class citrix {
  include ::packages

  $certs_copied_stamp = '/opt/Citrix/ICAClient/keystore/cacerts/.certs_copied'
  exec {
    "/bin/ln -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts && /bin/touch $certs_copied_stamp":
      creates => $certs_copied_stamp,
      require => [ Package['icaclient'], Package['ca-certificates'], ];
  }

  file {
    '/opt/Citrix/ICAClient/keystore/cacerts/gd_intermediate.crt':
      require => Package['icaclient'],
      source  => 'puppet:///modules/citrix/gd_intermediate.crt';
  }

  Package <| title == ca-certificates and title == icaclient |>
}
