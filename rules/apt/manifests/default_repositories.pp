class apt::default_repositories {
  include ::apt::backports
  include ::apt::multiarch
  include ::apt::repositories
  include ::apt::virtualbox

  case $debianversioncodename {
    'stretch': { include ::apt::ubuntu_repository }
  }

  $mirror = $mirror ? { undef => 'ftp.debian.org', default => "$mirror", }
  $securitymirror = 'security.debian.org'

  apt::repositories::setup {
    'apt':
      localmirror    => $localmirror,
      mirror         => $mirror,
      securitymirror => $securitymirror;
  }
}
