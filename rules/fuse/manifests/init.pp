class fuse {
  file {
    '/etc/fuse.conf':
      source => 'puppet:///modules/fuse/fuse.conf';
  }
}
