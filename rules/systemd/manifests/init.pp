class systemd {
  include ::packages

  file {
    '/etc/pam.d/systemd-user':
      source  => 'puppet:///modules/systemd/etc_pam.d_systemd-user';

    '/etc/systemd/system.conf':
      require => Package['systemd'],
      source  => 'puppet:///modules/systemd/system.conf';

    '/etc/sysusers.d':
      ensure => directory;

    '/etc/sysusers.d/puavo-os.conf':
      source => 'puppet:///modules/systemd/etc_sysusers.d_puavo-os.conf';

    # no persistent journal logs by default (not useful on fatclients)
    '/var/log/journal':
      ensure => absent,
      force  => true;
  }

  Package <| title == systemd |>
}
