class progressive_web_applications::apps {
  include ::progressive_web_applications

  Progressive_web_applications::Install {
    'graphical_analysis':
      app_id => 'ocgiedgmgfoocelalnmphikjnbgnnmdb',
      url    => 'https://graphicalanalysis.app';

    'teams':
      app_id  => 'ibdmcfbponkigmniimeihhiafmeifncn',
      browser => 'chrome',
      url     => 'https://teams.live.com/manifest.json';
  }
}
