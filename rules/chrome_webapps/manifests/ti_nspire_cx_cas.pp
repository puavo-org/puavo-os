class chrome_webapps::ti_nspire_cx_cas {
  include ::chrome_webapps

  file {
    '/usr/local/bin/puavo-ti-nspire-webapp':
      mode   => '0755',
      require => File['/usr/local/bin/puavo-chrome-webapp'],
      source => 'puppet:///modules/chrome_webapps/puavo-ti-nspire-webapp';

    '/usr/local/share/applications/puavo-ti-nspire-webapp.desktop':
      require => File['/usr/local/bin/puavo-ti-nspire-webapp'],
      source  => 'puppet:///modules/chrome_webapps/puavo-ti-nspire-webapp.desktop';
  }
}
