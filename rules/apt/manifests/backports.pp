class apt::backports {
  include ::packages

  $packages_from_backports = $packages::packages_from_backports

  file {
    '/etc/apt/preferences.d/20-backports.pref':
      content => template('apt/20-backports.pref');
  }
}
