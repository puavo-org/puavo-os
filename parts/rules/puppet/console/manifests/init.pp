class console {
  file {
    '/etc/init/ttyS0.conf':
      content => template('console/ttyS0.conf');
  }
}
