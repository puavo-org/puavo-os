class sudo {
  include config::logins,
          packages

  file {
    '/etc/sudoers.d/ltspadmins':
      content => template('sudo/sudoers.d/ltspadmins'),
      mode    => 440;
  }

  Package <| title == sudo |>
}
