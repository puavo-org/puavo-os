class apt::repositories {
  include ::apt

  define setup ($fasttrackmirror,
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

    # Do this in its own stage because in Buster
    # "fasttrack-archive-keyring" is found in buster-backports
    # that should be configured first.
##### XXX fasttrack missing from Bookworm, do not enable it (yet)
#   if $::puavoruleset == 'prepare-fasttrack' {
#     file {
#       '/etc/apt/sources.list.d/debian-fasttrack.list':
#         content => template('apt/debian-fasttrack.list'),
#         notify  => Exec['apt update'],
#         require => Package['fasttrack-archive-keyring'];
#     }
#
#     package {
#       'fasttrack-archive-keyring':
#         ensure => present;
#     }
#   }
  }
}
