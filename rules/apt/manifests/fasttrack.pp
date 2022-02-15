class apt::fasttrack {
  include ::apt
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

  # Require "/etc/apt/sources.list", because in Buster this package
  # comes from backports that is set up in our "sources.list".
  package {
    'fasttrack-archive-keyring':
      ensure  => present,
      require => [ Exec['apt update']
                 , File['/etc/apt/sources.list'] ];
  }
}
