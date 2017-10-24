class systemd {
  include ::packages

  file {
    '/etc/systemd/system.conf':
      require => Package['systemd'],
      source  => 'puppet:///modules/systemd/system.conf';
  }

  Package <| title == systemd |>
}
