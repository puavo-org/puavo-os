class bash {
  include config

  file {
    '/etc/bash.bashrc':
      content => template('bash/bash.bashrc');
  }

}
