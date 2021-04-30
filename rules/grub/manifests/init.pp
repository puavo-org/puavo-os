class grub {
  include ::grub::themes
  include ::puavo_conf

  file {
    [ '/boot', '/boot/grub', '/boot/grub/puavo' ]:
      ensure => directory;

    '/boot/grub/puavo/default.cfg':
      source => 'puppet:///modules/grub/default.cfg';
  }

  ::puavo_conf::hook {
    'puavo.grub.boot_default':
      script => 'setup_grub_default';

    'puavo.grub.developer_mode.enabled':
      script => 'setup_grub_environment';

    'puavo.grub.windows.enabled':
      script => 'setup_grub_environment';
  }
}
