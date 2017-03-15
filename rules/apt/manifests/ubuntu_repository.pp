class apt::ubuntu_repository {
  include ::apt
  include ::packages

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

  Package <| title == ubuntu-archive-keyring |>
}
