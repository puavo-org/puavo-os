class apt::default_repositories {
  include apt::repositories

  $mirror = $mirror ? { undef => 'ftp.debian.org', default => "$mirror", }
  $securitymirror = 'security.debian.org'

  apt::repositories::setup {
    'apt':
      mirror         => $mirror,
      securitymirror => $securitymirror;
  }
}
