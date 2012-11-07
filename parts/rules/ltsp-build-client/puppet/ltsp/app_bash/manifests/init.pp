class app_bash {
  include config,
          config::logins

  file {
    '/etc/bash.bashrc':
      content => template('app_bash/bash.bashrc');

    '/etc/skel/.bashrc':
      content => template('app_bash/etc_skel_.bashrc');
  }
}
