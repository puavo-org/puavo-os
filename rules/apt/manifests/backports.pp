class apt::backports {
  include ::packages::backports

  $packages_from_backports = $packages::backports::package_list

  file {
    '/etc/apt/preferences.d/20-backports.pref':
      content => template('apt/20-backports.pref');
  }
}
