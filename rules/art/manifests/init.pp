class art {
  include ::backgrounds
  include ::puavo_conf

  file {
    '/usr/share/puavo-art':
      source  => 'puppet:///modules/art/puavo-art',
      recurse => true;
  }

  ::puavo_conf::definition {
    'puavo-art.json':
      source => 'puppet:///modules/art/puavo-art.json';
  }
}
