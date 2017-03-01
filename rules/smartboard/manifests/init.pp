class smartboard {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-smartboard.json':
      source => 'puppet:///modules/smartboard/puavo-smartboard.json';
  }
}
