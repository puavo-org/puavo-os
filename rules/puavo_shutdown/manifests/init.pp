class puavo_shutdown {
  include ::dpkg

  dpkg::simpledivert {
    '/lib/systemd/systemd-shutdown':
      require => Package['systemd'];
  }

  file {
    '/lib/systemd/systemd-shutdown':
      mode    => '0755',
      require => Dpkg::Simpledivert['/lib/systemd/systemd-shutdown'],
      source  => 'puppet:///modules/puavo_shutdown/puavo_shutdown';
  }

  Package <| title == systemd |>
}
