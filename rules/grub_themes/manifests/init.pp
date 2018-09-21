class grub_themes {
  file {
    '/boot/grub/themes':
      ensure => directory;

    '/boot/grub/themes/StylishDark':
      recurse => true,
      source  => 'puppet:///modules/grub_themes/StylishDark';

    '/boot/grub/themes/Vimix':
      recurse => true,
      source  => 'puppet:///modules/grub_themes/Vimix';
  }
}
