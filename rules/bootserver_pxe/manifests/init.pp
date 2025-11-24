class bootserver_pxe {
  include ::packages
  include bootserver_pxe::generate_grub_pxe

  define tftpexport($filedir) {
    $filename = $title

    file {
      "/var/lib/tftpboot/${filename}":
        ensure  => file,
        mode    => '0644',
        source  => "file://${filedir}/${filename}";
    }
  }

  ::bootserver_pxe::tftpexport {
    [ 'grub-pxe-i386.0' ]:
      filedir => '/usr/lib/grub/pxe',
      require => Package['grub-pc'];

    [ 'efi32/grub-pxe-i386.efi' ]:
      filedir => '/usr/lib/grub/pxe',
      require => Package['grub-efi-ia32-bin'];

    [ 'efi64/grub-pxe-x64.efi' ]:
      filedir => '/usr/lib/grub/pxe',
      require => Package['grub-efi-amd64-bin'];

  }

  file {
    [ '/var'
    , '/var/lib'
    , '/var/lib/tftpboot'
    , '/var/lib/tftpboot/efi32'
    , '/var/lib/tftpboot/efi64' ]:
      ensure => directory;

    [ '/var/lib/tftpboot/efi32/ltsp', '/var/lib/tftpboot/efi64/ltsp' ]:
      ensure => link,
      target => '../ltsp';
  }

}
