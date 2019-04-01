class apt::repositories {
  include ::apt

  $other_releases = $debianversioncodename ? {
                      'buster' => [],
                      default  => {
                        'jessie' => 80,
                        'buster' => 60,
                      }
                    }

  define setup ($localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    $::apt::repositories::other_releases.each |String $distrib_version,
                                               Integer $pin_priority| {
      ::apt::debian_repository {
        $distrib_version:
          localmirror         => $localmirror,
          mirror              => $mirror,
          mirror_path         => $mirror_path,
          pin_priority        => $pin_priority,
          securitymirror      => $securitymirror,
          securitymirror_path => $securitymirror_path;
      }
    }

    file {
      '/etc/apt/preferences.d/00-puavo.pref':
        content => template('apt/00-puavo.pref'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list':
        content => template('apt/sources.list'),
        notify  => Exec['apt update'];

      '/etc/apt/trusted.gpg.d/opinsys.gpg':
        source => 'puppet:///modules/apt/opinsys.gpg';
    }
  }
}
