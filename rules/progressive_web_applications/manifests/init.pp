class progressive_web_applications {
  define install ($browser='', $url) {
    $pwa_name = $title

    exec {
      "/usr/local/lib/puavo-setup-pwa ${pwa_name} ${url} ${browser}":
        creates => "/var/lib/puavo-pwa/${pwa_name}",
        require => File['/usr/local/lib/puavo-setup-pwa'];
    }
  }

  file {
    '/usr/local/bin/puavo-pwa':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-pwa';

    '/usr/local/lib/puavo-setup-pwa':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-setup-pwa';
  }

  Progressive_web_applications::Install {
    'teams':
      browser => 'chrome',
      url     => 'https://teams.microsoft.com/manifest.json';
  }
}
