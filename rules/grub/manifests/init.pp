class grub {
  include ::grub::themes
  include ::puavo_conf

  $grub_version = '2.06-8'

  # Keep track of the "grub-efi-amd64-signed" package
  # version, even though currently installing that package
  # will break Grub in UEFI machines.
  $grub_version_signed = '1+2.06-8'

  file {
    [ '/boot', '/boot/grub', '/boot/grub/puavo' ]:
      ensure => directory;

    '/boot/grub/puavo/default.cfg':
      source => 'puppet:///modules/grub/default.cfg';

    '/etc/apt/preferences.d/50-grub.pref':
      content => template('grub/50-grub.pref');
  }

  ::puavo_conf::hook {
    'puavo.grub.boot_default':
      script => 'setup_grub_default';

    'puavo.grub.developer_mode.enabled':
      script => 'setup_grub_environment';

    'puavo.grub.windows.enabled':
      script => 'setup_grub_environment';
  }

  Package <|
       title == "grub-pc-amd64-bin"
    or title == "grub-pc-ia32-bin"
    or title == "grub-pc"
    or title == "grub-pc-bin"
  |> { ensure => $grub_version }

  Package <| title == "grub-efi-amd64-signed" |> { ensure => purged }
}
