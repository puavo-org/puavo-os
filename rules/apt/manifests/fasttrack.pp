class apt::fasttrack {
  include ::packages::fasttrack

  $packages_from_fasttrack = $packages::fasttrack::package_list

  if $packages_from_fasttrack.length() > 0 {
    file {
      '/etc/apt/preferences.d/20-fasttrack.pref':
        content => template('apt/20-fasttrack.pref');
    }
  } else {
    file {
      '/etc/apt/preferences.d/20-fasttrack.pref':
        ensure => absent;
    }
  }

  @package {
    'fasttrack-archive-keyring':
      ensure => present;
  }
}
