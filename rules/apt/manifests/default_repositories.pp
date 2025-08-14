class apt::default_repositories {
  include ::apt::backports
  # include ::apt::fasttrack            # XXX Trixie
  include ::apt::multiarch
  include ::apt::repositories

  $archivemirror        = 'archive.debian.org'
  $archivemirror_path   = '/debian'
  $fasttrackmirror      = 'fasttrack.debian.net'
  $fasttrackmirror_path = '/debian-fasttrack'
  $mirror               = 'httpredir.debian.org'
  $securitymirror       = 'security.debian.org'
  $securitymirror_path  = '/debian-security'

  apt::repositories::setup {
    'apt':
      archivemirror        => $archivemirror,
      archivemirror_path   => $archivemirror_path,
      fasttrackmirror      => $fasttrackmirror,
      fasttrackmirror_path => $fasttrackmirror_path,
      localmirror          => $localmirror,
      mirror               => $mirror,
      securitymirror       => $securitymirror,
      securitymirror_path  => $securitymirror_path;
  }
}
