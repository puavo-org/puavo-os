class progressive_web_applications {
  file {
    '/usr/local/lib/puavo-setup-pwa':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-setup-pwa';
  }
}
