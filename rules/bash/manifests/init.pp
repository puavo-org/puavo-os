class bash {
  include packages

  File { require => Package['bash'], }

  file {
    '/etc/bash.bashrc':
      content => template('bash/bash.bashrc');

    '/etc/skel/.bashrc':
      content => template('bash/etc_skel_.bashrc');
  }

  Package <| title == bash |>
}
