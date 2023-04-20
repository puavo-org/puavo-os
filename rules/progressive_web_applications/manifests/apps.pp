class progressive_web_applications::apps {
  include ::progressive_web_applications

  Progressive_web_applications::Install {
    'graphical_analysis':
      url     => 'https://graphicalanalysis.app';

    'teams':
      browser => 'chrome',
      url     => 'https://teams.live.com/manifest.json';
  }
}
