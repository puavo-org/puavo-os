class infotv {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-infotv.json':
      source => 'puppet:///modules/infotv/puavo-infotv.json';
  }
}
