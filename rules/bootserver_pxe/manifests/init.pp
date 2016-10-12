class bootserver_pxe {

  define bootserver_pxe::tftpexport($filename = $title) {
    file {
      "/var/lib/tftpboot/$filename":
        ensure  => file,
        mode    => '0644',
        require => Package['syslinux-common'],
        source  => "file:///usr/lib/syslinux/$filename";
    }
  }

  bootserver_pxe::tftpexport {
    ['menu.c32', 'chain.c32', 'ifcpu64.c32', 'pxelinux.0']:
    ;
  }

  file {
    ['/var', '/var/lib', '/var/lib/tftpboot']:
      ensure => directory;
  }

  package {
    'syslinux-common':
      ensure => present;
  }
}
