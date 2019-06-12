class grub::themes {
  include ::art
  include ::puavo_conf

  $vendor_logo_src_path =
    'puppet:///modules/art/puavo-art/puavo-os_logo-gray-300px.png'

  file {
    [ '/boot', '/boot/grub', '/boot/grub/themes' ]:
      ensure => directory;

    '/boot/grub/themes/StylishDark':
      recurse => true,
      source  => 'puppet:///modules/grub/StylishDark';

    '/boot/grub/themes/StylishDark/icons/vendor_logo.png':
      source => $vendor_logo_src_path;

    '/boot/grub/themes/Vimix':
      recurse => true,
      source  => 'puppet:///modules/grub/Vimix';
  }

  ::puavo_conf::definition {
    'puavo-grub.json':
      source => 'puppet:///modules/grub/puavo-grub.json';
  }
}
