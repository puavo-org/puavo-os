class art {
  include ::backgrounds

  file {
    '/usr/share/backgrounds/puavo-art':
      source  => 'puppet:///modules/art/puavo-art',
      recurse => true;
  }
}
