class progressive_web_applications {
  define install ($url) {
    $pwa_name = $title

    exec {
      "/usr/local/lib/puavo-setup-pwa ${pwa_name} ${url}":
        creates => "/var/lib/puavo-pwa/manifests/${name}.json",
        require => File['/usr/local/lib/puavo-setup-pwa'];
    }
  }

  file {
    '/usr/local/lib/puavo-setup-pwa':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-setup-pwa';
  }

  Progressive_web_applications::Install {
    'teams': url => 'https://teams.microsoft.com/manifest.json';
  }
}
