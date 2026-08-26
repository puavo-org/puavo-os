class pipewire {
  include ::packages
  include ::pipewire::jack

  file {
    [ '/etc/systemd/user/pipewire.service.d'
    , '/etc/systemd/user/pipewire.socket.d'
    , '/etc/systemd/user/pipewire-pulse.service.d'
    , '/etc/systemd/user/pipewire-pulse.socket.d'
    , '/etc/systemd/user/wireplumber.service.d' ]:
      ensure => directory;

    [ '/etc/systemd/user/pipewire.service.d/puavo-pipewire-systemd-service-tweaks.conf'
    , '/etc/systemd/user/pipewire.socket.d/puavo-pipewire-systemd-service-tweaks.conf'
    , '/etc/systemd/user/pipewire-pulse.service.d/puavo-pipewire-systemd-service-tweaks.conf'
    , '/etc/systemd/user/pipewire-pulse.socket.d/puavo-pipewire-systemd-service-tweaks.conf'
    , '/etc/systemd/user/wireplumber.service.d/puavo-pipewire-systemd-service-tweaks.conf' ]:
      require => Package['systemd'],
      source  => 'puppet:///modules/pipewire/puavo-pipewire-systemd-service-tweaks.conf';

    '/usr/local/sbin/puavo-pipewire-ctl':
      mode   => '0755',
      source => 'puppet:///modules/pipewire/puavo-pipewire-ctl';

    '/usr/local/sbin/puavo-pipewire-show-user-configuration':
      mode   => '0755',
      source => 'puppet:///modules/pipewire/puavo-pipewire-show-user-configuration';
  }

  Package <| title == systemd |>
}
