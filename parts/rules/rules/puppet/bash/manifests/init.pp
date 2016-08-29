class bash {
  file {
    '/etc/bash.bashrc':
      content => template('bash/bash.bashrc');
    '/etc/skel/.bashrc':
      content => template('bash/etc_skel_.bashrc');
  }
}
