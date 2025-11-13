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

    # set graphical target as the default in case set_systemd_default_target
    # is not run (the exam hosttype should not need it)
    '/etc/systemd/system/default.target':
      ensure => link,
      target => '/usr/lib/systemd/system/graphical.target';

    # Pulseaudio needs help in case "systemd --user" is missing.
    # This removes a link to /dev/null, masking autospawn activation.
    '/usr/lib/systemd/system/pulseaudio-enable-autospawn.service':
      ensure => absent;

    # no persistent journal logs by default (not useful on fatclients)
    '/var/log/journal':
      ensure => absent,
      force  => true;
  }

  Package <| title == systemd |>
}
