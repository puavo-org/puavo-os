class bootserver_pxe::generate_grub_pxe {
  include ::packages

  file {
    [ '/usr/lib/grub/pxe'
    , '/usr/lib/grub/pxe/efi64' ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
  }

  exec {
    'generate-grub-pxe-bios':
      command => "grub-mkimage -d /usr/lib/grub/i386-pc/ -O i386-pc-pxe -o ./grub-pxe-i386.0 -p '/' boot biosdisk chain echo linux normal pxe search test tftp",
      cwd     => '/usr/lib/grub/pxe',
      creates => '/usr/lib/grub/pxe/grub-pxe-i386.0',
      require => [ File['/usr/lib/grub/pxe']
                 , Package['grub-pc-bin'] ];

    'generate-grub-pxe-efi64':
      command => "grub-mkimage -d /usr/lib/grub/x86_64-efi/ -O x86_64-efi -o ./grub-pxe-x64.efi -p '/efi64' boot chain echo efinet fat linux normal part_gpt search test tftp",
      cwd     => '/usr/lib/grub/pxe/efi64',
      creates => '/usr/lib/grub/pxe/efi64/grub-pxe-x64.efi',
      require => [ File['/usr/lib/grub/pxe/efi64']
                 , Package['grub-efi-amd64-bin'] ];
  }

  Package <| title == grub-efi-amd64-bin
          or title == grub-pc-bin |>
}
