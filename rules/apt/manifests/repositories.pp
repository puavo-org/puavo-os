class apt::repositories {
  include ::apt

  # Need a special target because installing 'fasttrack-archive-keyring'
  # requires non-free on apt sources, which means that we need to
  # configure sources, run "apt update", only then we can install
  # fasttrack-archive-keyring and then configure debian-fasttrack.sources
  # and should run "apt update" again.
  exec {
    'apt update for fasttrack':
       command     => '/usr/bin/apt-get update',
       refreshonly => true;
  }

  define setup ($archivemirror,
                $archivemirror_path='',
                $fasttrackmirror,
                $fasttrackmirror_path='',
                $localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    file {
      '/etc/apt/preferences.d/00-puavo.pref':
        content => template('apt/00-puavo.pref'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list':
        ensure => absent;

      '/etc/apt/sources.list.d/debian.sources':
        content => template('apt/debian.sources'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list.d/debian-backports.sources':
        content => template('apt/debian-backports.sources'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list.d/debian-fasttrack.sources':
        content => template('apt/debian-fasttrack.sources'),
        notify  => Exec['apt update for fasttrack'],
        require => Package['fasttrack-archive-keyring'];

      # Put the local this into a separate file so it can be excluded
      # in the image build along with the actual archive.
      '/etc/apt/sources.list.d/puavo-os-local.sources':
        content => template('apt/puavo-os-local.sources'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list.d/puavo-os-remote.sources':
        content => template('apt/puavo-os-remote.sources'),
        notify  => Exec['apt update'];

      '/usr/local/share/keyrings':
        ensure => directory;

      '/usr/local/share/keyrings/opinsys.gpg':
        before => Exec['apt update'],
        source => 'puppet:///modules/apt/opinsys.gpg';
    }

    package {
      'fasttrack-archive-keyring':
        ensure  => present,
        require => Exec['apt update'];
    }
  }
}
