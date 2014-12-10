class bootserver_krb5kdc {

  file {
    '/etc/init/krb5-kdc.override':
      source => 'puppet:///modules/bootserver_krb5kdc/krb5-kdc.override';

    '/etc/logrotate.d/kdc':
      source => 'puppet:///modules/bootserver_krb5kdc/logrotate.conf';
  }

}
