class systemd {
  include ::packages
  include ::systemd::sysusers

  file {
    '/etc/systemd/journald.conf':
      require => Package['systemd'],
      source  => 'puppet:///modules/systemd/journald.conf';

    '/etc/systemd/system.conf':
      require => Package['systemd'],
      source  => 'puppet:///modules/systemd/system.conf';

    # set graphical target as the default in case set_systemd_default_target
    # is not run (the exam hosttype should not need it)
    '/etc/systemd/system/default.target':
      ensure => link,
      target => '/usr/lib/systemd/system/graphical.target';
  }

  Package <| title == systemd |>
}
