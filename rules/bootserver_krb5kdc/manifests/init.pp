class bootserver_krb5kdc {
  include ::packages

  file {
    '/etc/default/krb5-kdc':
      require => Package['krb5-kdc'],
      source  => 'puppet:///modules/bootserver_krb5kdc/etc_default_krb5-kdc';

    '/etc/init.d/krb5-kdc':
      mode    => '0755',
      require => Package['krb5-kdc'],
      source  => 'puppet:///modules/bootserver_krb5kdc/etc_init.d_krb5-kdc';
  }

  Package <| title == krb5-kdc |>
}

#  file {
#    '/etc/init/krb5-kdc.override':
#      source => 'puppet:///modules/bootserver_krb5kdc/krb5-kdc.override';
#
#    '/etc/krb5kdc/kdc.conf':
#      mode    => '0644',
#      content => template('bootserver_krb5kdc/kdc.conf');
#
#    '/etc/krb5.conf':
#      mode    => '0644',
#      content => template('bootserver_krb5kdc/krb5.conf');
#
#    '/etc/logrotate.d/kdc':
#      source => 'puppet:///modules/bootserver_krb5kdc/logrotate.conf';
#  }
