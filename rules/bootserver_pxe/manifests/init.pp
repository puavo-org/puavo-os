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

    'pxelinux.0':
      filedir => '/usr/lib/PXELINUX',
      require => Package['pxelinux'];
  }

  file {
    [ '/var', '/var/lib', '/var/lib/tftpboot' ]:
      ensure => directory;
  }

  Package <| title == pxelinux
          or title == syslinux-common |>
}
