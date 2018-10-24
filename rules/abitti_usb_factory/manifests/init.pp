class abitti_usb_factory {
  include ::puavo_conf

  ::puavo_conf::definition {
    'abitti_usb_factory.json':
      source => 'puppet:///modules/abitti_usb_factory/abitti_usb_factory.json';
  }

  ::puavo_conf::script {
    'setup_abitti_usb_factory':
      source => 'puppet:///modules/abitti_usb_factory/setup_abitti_usb_factory';
  }
}
