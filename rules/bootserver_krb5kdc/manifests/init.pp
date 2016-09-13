class bootserver_krb5kdc {

  file {
    '/etc/init/krb5-kdc.override':
      source => 'puppet:///modules/bootserver_krb5kdc/krb5-kdc.override';

    '/etc/krb5kdc/kdc.conf':
      mode    => '0644',
      notify  => Service['krb5-kdc'],
      content => template('bootserver_krb5kdc/kdc.conf');

    '/etc/krb5.conf':
      mode    => '0644',
      notify  => Service['krb5-kdc'],
      content => template('bootserver_krb5kdc/krb5.conf');

    '/etc/logrotate.d/kdc':
      source => 'puppet:///modules/bootserver_krb5kdc/logrotate.conf';
  }

  service {
    'krb5-kdc':
      ensure => running;
  }

}
