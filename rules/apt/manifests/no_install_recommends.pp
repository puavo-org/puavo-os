class apt::no_install_recommends {
  include ::apt

  file {
    '/etc/apt/apt.conf.d/80puavo-no-install-recommends':
      source => 'puppet:///modules/apt/80puavo-no-install-recommends';
  }
}
