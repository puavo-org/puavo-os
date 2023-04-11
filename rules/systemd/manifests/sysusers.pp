class systemd::sysusers {
  include ::dpkg

  dpkg::divert {
    '/bin/systemd-sysusers':
      dest => '/bin/systemd-sysusers.orig';
  }

  file {
    '/etc/sysusers.d':
      ensure => directory;

    '/etc/sysusers.d/puavo-os.conf':
      source => 'puppet:///modules/systemd/etc_sysusers.d_puavo-os.conf';

    '/bin/systemd-sysusers':
      mode    => '0755',
      require => Dpkg::Divert['/bin/systemd-sysusers'],
      source  => 'puppet:///modules/systemd/systemd-sysusers';
  }
}
