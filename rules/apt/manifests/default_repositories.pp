class apt::default_repositories {
  include ::apt::backports
  include ::apt::multiarch
  include ::apt::repositories
  include ::apt::virtualbox

  $mirror = $mirror ? { undef => 'ftp.debian.org', default => "$mirror", }
  $securitymirror = 'security.debian.org'
  $securitymirror_path = '/debian-security'

  apt::repositories::setup {
    'apt':
      localmirror         => $localmirror,
      mirror              => $mirror,
      securitymirror      => $securitymirror,
      securitymirror_path => $securitymirror_path;
  }
}
