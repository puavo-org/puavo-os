class apt::repositories {
  include apt

  $mirror = $lsbdistcodename ? {
    'quantal' => 'old-releases.ubuntu.com',
    default   => 'archive.ubuntu.com',
  }

  $securitymirror = $lsbdistcodename ? {
    'quantal' => 'old-releases.ubuntu.com',
    default   => 'security.ubuntu.com',
  }

  file {
    '/etc/apt/sources.list':
      content => template('apt/sources.list'),
      notify  => Exec['apt update'];
  }

  # define some apt keys and repositories for use
  @apt::repository {
    'partner':
      aptline => "http://archive.canonical.com/ubuntu $lsbdistcodename partner";
  }
}
