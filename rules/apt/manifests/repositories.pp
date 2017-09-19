class apt::repositories {
  include ::apt

  $other_releases = $debianversioncodename ? {
                      'buster' => [],
                      default  => [ 'wheezy', 'jessie', 'buster', ],
                    }

  define setup ($localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    ::apt::debian_repository {
      $::apt::repositories::other_releases:
        localmirror         => $localmirror,
        mirror              => $mirror,
        mirror_path         => $mirror_path,
        securitymirror      => $securitymirror,
        securitymirror_path => $securitymirror_path;
    }

    file {
      '/etc/apt/preferences.d/00-puavo.pref':
        content => template('apt/00-puavo.pref'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list':
        content => template('apt/sources.list'),
        notify  => Exec['apt update'];
    }
  }
}
