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

    [ '/etc/systemd/user/pipewire.service.d/no-pipewire-for-admins-or-gdm.conf'
    , '/etc/systemd/user/pipewire.socket.d/no-pipewire-for-admins-or-gdm.conf'
    , '/etc/systemd/user/pipewire-pulse.service.d/no-pipewire-for-admins-or-gdm.conf'
    , '/etc/systemd/user/pipewire-pulse.socket.d/no-pipewire-for-admins-or-gdm.conf'
    , '/etc/systemd/user/wireplumber.service.d/no-pipewire-for-admins-or-gdm.conf' ]:
      require => Package['systemd'],
      source  => 'puppet:///modules/pipewire/no-pipewire-for-admins-or-gdm.conf';

    '/usr/local/sbin/puavo-pipewire-show-user-configuration':
      mode   => '0755',
      source => 'puppet:///modules/pipewire/puavo-pipewire-show-user-configuration';
  }

  Package <| title == systemd |>
}
