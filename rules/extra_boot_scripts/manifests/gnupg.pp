class extra_boot_scripts::gnupg {
  file {
    '/root/.ebs-gnupg':
      ensure => directory,
      mode   => '0700';

    '/root/.ebs-gnupg/pubring.kbx':
      mode   => '0644',
      source => 'puppet:///modules/extra_boot_scripts/pubring.kbx';

    '/root/.ebs-gnupg/trustdb.gpg':
      mode   => '0644',
      source => 'puppet:///modules/extra_boot_scripts/trustdb.gpg';
  }
}
