class app_bash {
  include config,
          config::logins,
          packages

  file {
    '/etc/bash.bashrc':
      content => template('app_bash/bash.bashrc'),
      require => Package['bash'];

    '/etc/skel/.bashrc':
      content => template('app_bash/etc_skel_.bashrc'),
      require => Package['bash'];
  }

  Package <| title == "bash" |>
}
