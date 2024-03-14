class bootserver_pxe::generate_grub_pxe {
  include ::packages

  file {
    [ '/usr/lib/grub/pxe'
    , '/usr/lib/grub/pxe/efi32'
    , '/usr/lib/grub/pxe/efi64' ]:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  exec {
    "grub-mkimage -d /usr/lib/grub/i386-pc/ -O i386-pc-pxe -o ./grub-pxe-i386.0 -p '/var/lib/tftpboot' pxe tftp":
      cwd => '/usr/lib/grub/pxe',
      creates => '/usr/lib/grub/pxe/grub-pxe-i386.0'
  }

  exec {
    "grub-mkimage -d /usr/lib/grub/i386-efi/ -O i386-efi -o ./grub-pxe-i386.efi -p '/var/lib/tftpboot/efi32' efinet tftp":
      cwd => '/usr/lib/grub/pxe/efi32',
      creates => '/usr/lib/grub/pxe/efi32/grub-pxe-i386.efi'
  }

  exec {
    "grub-mkimage -d /usr/lib/grub/x86_64-efi/ -O x86_64-efi -o ./grub-pxe-x64.efi -p '/var/lib/tftpboot/efi64' efinet tftp":
      cwd => '/usr/lib/grub/pxe/efi64',
      creates => '/usr/lib/grub/pxe/efi64/grub-pxe-x64.efi'
  }
}
