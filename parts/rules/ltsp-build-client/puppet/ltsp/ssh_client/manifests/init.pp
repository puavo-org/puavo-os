class ssh_client {
  file {
    '/etc/ssh/ssh_config':
      content => template('ssh_client/ssh_config'),
      require => Package['openssh-client'];
  }
}
