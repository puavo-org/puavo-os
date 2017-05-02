class apt::repositories {
  include ::apt

  $old_releases = $debianversioncodename ? {
                    'jessie' => [ 'wheezy',           ],
                    default  => [ 'wheezy', 'jessie', ],
                  }

  define setup ($localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    ::apt::debian_repository {
      $::apt::repositories::old_releases:
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
