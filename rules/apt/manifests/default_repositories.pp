class apt::default_repositories {
  include ::apt::backports
  include ::apt::multiarch
  include ::apt::nodejs
  include ::apt::repositories

  # XXX issues with using Ubuntu repositories in Buster
  # XXX (could we drop them?)
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
