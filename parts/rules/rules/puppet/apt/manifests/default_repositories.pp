class apt::default_repositories {
  include apt::repositories

  $mirror = $lsbdistcodename ? {
    'quantal' => 'old-releases.ubuntu.com',
    default   => 'archive.ubuntu.com',
  }

  $partnermirror = 'archive.canonical.com'

  $securitymirror = $lsbdistcodename ? {
    'quantal' => 'old-releases.ubuntu.com',
    default   => 'security.ubuntu.com',
  }

  apt::repositories::setup {
    'apt':
      mirror         => $mirror,
      partnermirror  => $partnermirror,
      securitymirror => $securitymirror;
  }
}
