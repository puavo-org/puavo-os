class bootserver_slapd {
  include ::packages
  include ::puavo_conf

  File { require => Package['slapd'] }
  file {
    '/etc/systemd/system/slapd.service':
      require => Package['systemd'],
      source  => 'puppet:///modules/bootserver_slapd/slapd.service';

    '/usr/local/lib/puavo-service-wait-for-slapd':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_slapd/puavo-service-wait-for-slapd';
  }

  ::puavo_conf::script {
    'setup_slapd':
      source => 'puppet:///modules/bootserver_slapd/setup_slapd';
  }

  Package <| title == slapd or title == systemd |>
}
