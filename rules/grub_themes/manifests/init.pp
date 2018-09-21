class grub_themes {
  include ::plymouth    # for (opinsys) logo.png
  include ::puavo_conf

  $vendor_logo_src_path =
    'puppet:///modules/plymouth/theme/opinsys-dark/logo.png';

  file {
    [ '/boot', '/boot/grub', '/boot/grub/themes' ]:
      ensure => directory;

    '/boot/grub/themes/StylishDark':
      recurse => true,
      source  => 'puppet:///modules/grub_themes/StylishDark';

    '/boot/grub/themes/StylishDark/icons/vendor_logo.png':
      source => $vendor_logo_src_path;

    '/boot/grub/themes/Vimix':
      recurse => true,
      source  => 'puppet:///modules/grub_themes/Vimix';
  }

  ::puavo_conf::definition {
    'puavo-grub.json':
      source => 'puppet:///modules/grub_themes/puavo-grub.json';
  }
}
