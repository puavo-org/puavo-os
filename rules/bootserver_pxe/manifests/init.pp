class bootserver_pxe {
  include ::packages

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
    [ 'chain.c32'
    , 'ifcpu64.c32'
    , 'ldlinux.c32'
    , 'libcom32.c32'
    , 'libutil.c32'
    , 'menu.c32' ]:
      filedir => '/usr/lib/syslinux/modules/bios',
      require => Package['syslinux-common'];

    [ 'efi32/syslinux.efi' ]:
      filedir => '/usr/lib/SYSLINUX.EFI',
      require => Package['syslinux-efi'];

    [ 'efi32/chain.c32'
    , 'efi32/ifcpu64.c32'
    , 'efi32/ldlinux.e32'
    , 'efi32/libutil.c32'
    , 'efi32/menu.c32'
    , 'efi32/syslinux.c32' ]:
      filedir => '/usr/lib/syslinux/modules',
      require => Package['syslinux-efi'];

    [ 'efi64/syslinux.efi' ]:
      filedir => '/usr/lib/SYSLINUX.EFI',
      require => Package['syslinux-efi'];

    [ 'efi64/chain.c32'
    , 'efi64/ifcpu64.c32'
    , 'efi64/ldlinux.e64'
    , 'efi64/libutil.c32'
    , 'efi64/menu.c32'
    , 'efi64/syslinux.c32' ]:
      filedir => '/usr/lib/syslinux/modules',
      require => Package['syslinux-efi'];

    'pxelinux.0':
      filedir => '/usr/lib/PXELINUX',
      require => Package['pxelinux'];
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

  Package <| title == pxelinux
          or title == syslinux-common
          or title == syslinux-efi |>
}
