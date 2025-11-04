class systemd {
  include ::packages
  include ::systemd::sysusers

  file {
    '/etc/systemd/system.conf':
      require => Package['systemd'],
      source  => 'puppet:///modules/systemd/system.conf';

    # disable "systemd --user" service due to issues with it
    '/etc/systemd/system/user@.service':
      ensure => link,
      target => '/dev/null';

    # no persistent journal logs by default (not useful on fatclients)
    '/var/log/journal':
      ensure => absent,
      force  => true;
  }

  Package <| title == systemd |>
}
