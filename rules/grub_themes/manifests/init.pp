class grub_themes {
  include ::puavo_conf

  file {
    [ '/boot', '/boot/grub', '/boot/grub/themes' ]:
      ensure => directory;

    '/boot/grub/themes/StylishDark':
      recurse => true,
      source  => 'puppet:///modules/grub_themes/StylishDark';

    '/boot/grub/themes/Vimix':
      recurse => true,
      source  => 'puppet:///modules/grub_themes/Vimix';
  }

  ::puavo_conf::definition {
    'puavo-grub.json':
      source => 'puppet:///modules/grub_themes/puavo-grub.json';
  }
}
