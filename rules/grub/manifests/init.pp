class grub {
  include ::grub::themes
  include ::puavo_conf

  ::puavo_conf::hook {
    'puavo.grub.boot_default':
      script => 'setup_grub_default';

    'puavo.grub.developer_mode.enabled':
      script => 'setup_grub_environment';

    'puavo.grub.windows.enabled':
      script => 'setup_grub_environment';
  }
}
