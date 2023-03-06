class trusty_libs::file_unpack {
  file {
    '/usr/local/lib/puavo-unpack-a-file-from-deb':
      mode   => '0755',
      source => 'puppet:///modules/trusty_libs/puavo-unpack-a-file-from-deb';
  }
}
