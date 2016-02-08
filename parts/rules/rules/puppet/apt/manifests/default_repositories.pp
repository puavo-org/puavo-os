class apt::default_repositories {
  include apt::repositories

  $mirror = 'archive.debian.org'
  $securitymirror = 'security.debian.org'

  apt::repositories::setup {
    'apt':
      mirror         => $mirror,
      securitymirror => $securitymirror;
  }
}
