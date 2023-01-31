class apt::default_repositories {
  include ::apt::backports
  # include ::apt::fasttrack    # XXX not on bookworm yet
  include ::apt::multiarch
  include ::apt::repositories
  include ::apt::winehq

  $fasttrackmirror = 'fasttrack.debian.net'
  $fasttrackmirror_path = '/debian'
  $mirror = 'httpredir.debian.org'
  $securitymirror = 'security.debian.org'
  $securitymirror_path = '/debian-security'

  apt::repositories::setup {
    'apt':
      fasttrackmirror      => $fasttrackmirror,
      fasttrackmirror_path => $fasttrackmirror_path,
      localmirror          => $localmirror,
      mirror               => $mirror,
      securitymirror       => $securitymirror,
      securitymirror_path  => $securitymirror_path;
  }
}
