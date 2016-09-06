class packages::sssd_install_workaround {
  # XXX puavo-ltsp-client depends on sssd, but it refuses to install
  # XXX on ltsp-chroot without this (because it tries to be smart
  # XXX and autogenerate its configuration file, but it fails).

  file {
    '/etc/sssd':
      ensure => directory;

    '/etc/sssd/sssd.conf':
      ensure => present;
  }
}
