class plymouth_theme::initramfs {
  # XXX move this to a separate module once something else than plymouth needs
  # XXX this?

  include packages

  exec {
    'update-initramfs':
      command     => '/usr/sbin/update-initramfs -k all -u',
      refreshonly => true,
      require     => Package['initramfs-tools'];
  }

  Package <| title == initramfs-tools |>
}
