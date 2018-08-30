class bootserver_krb5kdc {
  include ::bootserver_slapd
  include ::packages
  include ::puavo_conf

  file {
    '/etc/systemd/system/krb5-kdc.service.d':
      ensure => directory;

    '/etc/systemd/system/krb5-kdc.service.d/override.conf':
      require => File['/usr/local/lib/puavo-service-wait-for-slapd'],
      source  => 'puppet:///modules/bootserver_krb5kdc/krb5-kdc_override.conf';

    '/etc/logrotate.d/kdc':
      require => Package['logrotate'],
      source  => 'puppet:///modules/bootserver_krb5kdc/logrotate.conf';
  }

  ::puavo_conf::script {
    'setup_krb5kdc':
      source => 'puppet:///modules/bootserver_krb5kdc/setup_krb5kdc';
  }

  Package <| title == krb5-kdc
          or title == logrotate |>
}
