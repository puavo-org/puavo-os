class bootserver_pxe::generate_grub_pxe {
  include ::packages

  file {
    '/usr/lib/grub/pxe':
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
  }

  Package <| title == grub-pc-bin |>
}
