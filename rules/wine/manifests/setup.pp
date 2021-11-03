class wine::setup {
  file {
    '/usr/local/bin/puavo-wine-setup':
      mode    => '0755',
      source  => 'puppet:///modules/wine/puavo-wine-setup';
  }
}
