class apt::ubuntu_repository {
  include ::apt

  $ubuntu_mirror  = 'archive.ubuntu.com'
  $ubuntu_version = 'xenial'

  file {
    '/etc/apt/preferences.d/00-ubuntu.pref':
      content => template('apt/00-ubuntu.pref'),
      notify  => Exec['apt update'];

    '/etc/apt/sources.list.d/ubuntu.list':
      content => template('apt/ubuntu_apt_sources.list'),
      notify  => Exec['apt update'];
  }

  # Exceptionally do not add this to ::packages,
  # because these apt::* rules should be applied before everything in
  # ::packages are installable.
  package {
    'ubuntu-archive-keyring':
      ensure => present;
  }
}
