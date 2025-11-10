class puavo_shutdown {
  include ::dpkg

  dpkg::simpledivert {
    '/usr/lib/systemd/systemd-shutdown':
      require => Package['systemd'];
  }

  file {
    '/usr/lib/systemd/systemd-shutdown':
      mode    => '0755',
      require => Dpkg::Simpledivert['/usr/lib/systemd/systemd-shutdown'],
      source  => 'puppet:///modules/puavo_shutdown/puavo_shutdown';
  }

  Package <| title == systemd |>
}
