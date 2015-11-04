class opinsys_apt_repositories {
  include apt

  $subdir = $lsbdistcodename ? {
              'precise' => 'git-precise',
              'quantal' => 'git-legacy1',
              default   => "git-master",
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

    'libreoffice-5-0':
      aptline => "http://archive.opinsys.fi/libreoffice-5-0 $lsbdistcodename main restricted universe multiverse";

    'repo':
      aptline => "http://archive.opinsys.fi/blobs $lsbdistcodename main restricted universe multiverse";

    'x2go':
      aptline => "http://archive.opinsys.fi/x2go $lsbdistcodename main restricted universe multiverse";

    'xorg-updates':
      aptline => "http://archive.opinsys.fi/git-xorg-updates $lsbdistcodename main restricted universe multiverse";
  }

  file {
    '/etc/apt/preferences.d/opinsys.pref':
      content => template('opinsys_apt_repositories/opinsys.pref');
  }
}
