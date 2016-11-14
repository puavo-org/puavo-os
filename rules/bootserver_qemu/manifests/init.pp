class bootserver_qemu {

  file {
    '/usr/share/qemu/pxe-e1000.rom':
      ensure  => link,
      require => [ Package['ipxe-qemu'], Package['qemu-system-x86'] ],
      target  => '/usr/lib/ipxe/82540em.rom';

    '/usr/share/qemu/pxe-virtio.rom':
      ensure  => link,
      require => [ Package['ipxe-qemu'], Package['qemu-system-x86'] ],
      target  => '/usr/lib/ipxe/virtio-net.rom';
  }

  package {
    [ 'ipxe-qemu'
    , 'qemu-system-x86' ]:
      ensure => present;
  }
}
