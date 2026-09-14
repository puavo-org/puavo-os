class chrome_webapps {
  file {
    '/usr/local/bin/puavo-chrome-webapp':
      mode   => '0755',
      source => 'puppet:///modules/chrome_webapps/puavo-chrome-webapp';
  }
}
