class art {
  include ::backgrounds
  include ::puavo_conf
  include ::puavo_external_files

  file {
    '/etc/puavo-external-files-actions.d/background_images':
      mode   => '0755',
      source => 'puppet:///modules/art/etc_puavo-external-files-actions.d_background_images';

    '/usr/share/puavo-art':
      source  => 'puppet:///modules/art/puavo-art',
      recurse => true;
  }

  ::puavo_conf::definition {
    'puavo-art.json':
      source => 'puppet:///modules/art/puavo-art.json';
  }
}
