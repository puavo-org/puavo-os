class fuse {
  # This is needed by the "ekapeli" puavo-pkg package,
  # possibly some other components as well.
  file {
    '/etc/fuse.conf':
      source => 'puppet:///modules/fuse/fuse.conf';
  }
}
