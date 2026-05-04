class abitti2::usb_factory {
  $image_dir = '/usr/local/share/puavo-download-usb-factory-images'

  file {
    $image_dir:
      ensure => directory;

    "${image_dir}/UI-blue.png":
      source => 'puppet:///modules/abitti2/UI-blue.png';

    "${image_dir}/UI-mintgreen.png":
      source => 'puppet:///modules/abitti2/UI-mintgreen.png';

    "${image_dir}/UI-purple.png":
      source => 'puppet:///modules/abitti2/UI-purple.png';

    '/usr/local/bin/puavo-download-usb-factory-images':
      mode    => '0755',
      require => [ File["${image_dir}/UI-blue.png"]
                 , File["${image_dir}/UI-mintgreen.png"]
                 , File["${image_dir}/UI-purple.png"] ],
      source  => 'puppet:///modules/abitti2/puavo-download-usb-factory-images';
  }
}
