class ca_certificate_workarounds {
  exec {
    # remove an expired certificate that causes bad behaviour in old openssl
    'remove an expired certificate':
      command => '/bin/sed -i \'/^mozilla\/DST_Root_CA_X3.crt$/d\' /etc/ca-certificates.conf && /usr/sbin/update-ca-certificates -f',
      onlyif  => '/usr/bin/test -e /etc/ssl/certs/DST_Root_CA_X3.pem';
  }
}
