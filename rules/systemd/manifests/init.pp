class systemd {
  include ::packages
  include ::systemd::sysusers

  file {
    '/etc/pam.d/systemd-user':
      source  => 'puppet:///modules/systemd/etc_pam.d_systemd-user';

    '/etc/systemd/system.conf':
      require => Package['systemd'],
      source  => 'puppet:///modules/systemd/system.conf';

    # disable "systemd --user" service due to issues with it
    '/etc/systemd/system/user@.service':
      ensure => link,
      target => '/dev/null';

    # Pulseaudio needs help in case "systemd --user" is missing.
    # This removes a link to /dev/null, masking autospawn activation.
    '/usr/lib/systemd/system/pulseaudio-enable-autospawn.service':
      ensure => absent;

    # no persistent journal logs by default (not useful on fatclients)
    '/var/log/journal':
      ensure => absent,
      force  => true;
  }

  # We use ntpd.  Oddly enough, even though this should not
  # affect ntpd, in some cases systemd-timesyncd can block it
  # from starting up.  Do not try to use "service", we do not run
  # systemd inside the container in image build, thus the service
  # can not be disabled through the puppet "service"-type.
  file {
    '/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service':
       ensure  => absent,
       require => Package['systemd'];
  }

  Package <| title == systemd |>
}
