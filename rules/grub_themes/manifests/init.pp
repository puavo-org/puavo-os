class themes {

  file {
    '/boot/grub/themes':
      ensure => directory;

    '/boot/grub/themes/StylishDark':
      recurse => true,
      source  => 'puppet:///modules/themes/StylishDark';

    '/boot/grub/themes/Vimix':
      recurse => true,
      source  => 'puppet:///modules/themes/Vimix';
  }
}
