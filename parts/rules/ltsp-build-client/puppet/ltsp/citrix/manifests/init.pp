class citrix {
  require packages

  $certs_copied_stamp = '/opt/Citrix/ICAClient/keystore/cacerts/.certs_copied'
  exec {
    "/bin/ln -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts && /bin/touch $certs_copied_stamp":
      creates => $certs_copied_stamp;
  }

  Package <| title == ca-certificates and title == icaclient |>
}
