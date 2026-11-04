class progressive_web_applications::apps {
  include ::packages
  include ::progressive_web_applications

  exec {
    'update-mime-database for graphical_analysis':
      command     => '/usr/bin/update-mime-database /usr/share/mime',
      refreshonly => true,
      require     => Package['shared-mime-info'];
  }

  file {
    '/usr/share/mime/packages/puavo-vernier-ga.xml':
      notify  => Exec['update-mime-database for graphical_analysis'],
      require => Package['shared-mime-info'],
      source  => 'puppet:///modules/progressive_web_applications/puavo-vernier-ga.xml';
  }

  Package <| title == shared-mime-info |>

  Progressive_web_applications::Install {
    'graphical_analysis':
      app_id => 'ocgiedgmgfoocelalnmphikjnbgnnmdb',
      url    => 'https://graphicalanalysis.app';

    'spotify':
      app_id  => 'pjibgclleladliembfgfagdaldikeohf',
      browser => 'chrome',
      url     => 'https://open.spotify.com/?utm_source=pwa_install';

    'teams':
      app_id  => 'cifhbcnohmdccbgoicgdjpfamggdegmo',
      browser => 'chrome',
      url     => 'https://teams.microsoft.com/manifest.json';
  }
}
