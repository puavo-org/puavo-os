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

    [ 'efi64/grub-pxe-x64.efi' ]:
      filedir => '/usr/lib/grub/pxe',
      require => Package['grub-efi-amd64-bin'];

  }

  file {
    [ '/var'
    , '/var/lib'
    , '/var/lib/tftpboot'
    , '/var/lib/tftpboot/efi64' ]:
      ensure => directory;
  }

}
