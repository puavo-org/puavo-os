class puavo_pkg::gnupg {
  file {
    '/root/.pkg-gnupg':
      ensure => directory,
      mode   => '0700';

    '/root/.pkg-gnupg/pubring.kbx':
      mode   => '0644',
      source => 'puppet:///modules/puavo_pkg/pubring.kbx';

    '/root/.pkg-gnupg/trustdb.gpg':
      mode   => '0644',
      source => 'puppet:///modules/puavo_pkg/trustdb.gpg';
  }
}
