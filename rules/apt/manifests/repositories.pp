class apt::repositories {
  include ::apt

  define setup ($localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    file {
      '/etc/apt/preferences.d/00-puavo.pref':
        content => template('apt/00-puavo.pref'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list':
        content => template('apt/sources.list'),
        notify  => Exec['apt update'];

      # Put the local this into a separate file so it can be excluded
      # in the image build along with the actual archive.
      '/etc/apt/sources.list.d/puavo-os-local.list':
        content => template('apt/puavo-os-local.list'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list.d/puavo-os-remote.list':
        content => template('apt/puavo-os-remote.list'),
        notify  => Exec['apt update'];

      '/etc/apt/trusted.gpg.d/opinsys.gpg':
        before => Exec['apt update'],
        source => 'puppet:///modules/apt/opinsys.gpg';
    }
  }
}
