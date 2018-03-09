class bootserver_krb5kdc {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/default/krb5-kdc':
      require => Package['krb5-kdc'],
      source  => 'puppet:///modules/bootserver_krb5kdc/etc_default_krb5-kdc';

    '/etc/init.d/krb5-kdc':
      mode    => '0755',
      require => Package['krb5-kdc'],
      source  => 'puppet:///modules/bootserver_krb5kdc/etc_init.d_krb5-kdc';

    # XXX what to do this this?
    # '/etc/init/krb5-kdc.override':
    #   source => 'puppet:///modules/bootserver_krb5kdc/krb5-kdc.override';

     '/etc/logrotate.d/kdc':
       require => Package['logrotate'],
       source => 'puppet:///modules/bootserver_krb5kdc/logrotate.conf';
  }

  ::puavo_conf::script {
    'setup_krb5kdc':
      source => 'puppet:///modules/bootserver_krb5kdc/setup_krb5kdc';
  }

  Package <| title == krb5-kdc
          or title == logrotate |>
}
