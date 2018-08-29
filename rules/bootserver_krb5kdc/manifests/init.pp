class bootserver_krb5kdc {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/systemd/system/krb5-kdc.service.d':
      ensure => directory;

    '/etc/systemd/system/krb5-kdc.service.d/override.conf':
      source => 'puppet:///modules/bootserver_krb5kdc/krb5-kdc_override.conf';

    '/etc/logrotate.d/kdc':
      require => Package['logrotate'],
      source  => 'puppet:///modules/bootserver_krb5kdc/logrotate.conf';

    '/usr/local/lib/puavo-kdc-wait-for-slapd':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_krb5kdc/puavo-kdc-wait-for-slapd';
  }

  ::puavo_conf::script {
    'setup_krb5kdc':
      source => 'puppet:///modules/bootserver_krb5kdc/setup_krb5kdc';
  }

  Package <| title == krb5-kdc
          or title == logrotate |>
}
