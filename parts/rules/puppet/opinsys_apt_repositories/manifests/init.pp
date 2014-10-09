class opinsys_apt_repositories {
  include apt

  # XXX this twist should probably go away, just use:
  # XXX $subdir = "git-$lsbdistcodename"
  $subdir = $lsbdistcodename ? {
              'quantal' => 'git-master',
              default   => "git-$lsbdistcodename",
            }

  # define some apt keys and repositories for use

  apt::key {
    'opinsys-repo.gpgkey':
      key_id => 'C0F0F8B7',
      key_source
        => 'puppet:///modules/opinsys_apt_repositories/keys/opinsys-repo.gpgkey';
  }

  Apt::Repository { require => Apt::Key['opinsys-repo.gpgkey'], }
  @apt::repository {
    'archive':
      aptline => "http://archive.opinsys.fi/$subdir $lsbdistcodename main restricted universe multiverse";

    'kernels':
      aptline => "http://archive.opinsys.fi/kernels $lsbdistcodename main restricted universe multiverse";

    'repo':
      aptline => "http://archive.opinsys.fi/blobs $lsbdistcodename main restricted universe multiverse";

    'x2go':
      aptline => "http://archive.opinsys.fi/x2go $lsbdistcodename main restricted universe multiverse";
  }

  file {
    '/etc/apt/preferences.d/opinsys.pref':
      content => template('opinsys_apt_repositories/opinsys.pref');
  }
}
