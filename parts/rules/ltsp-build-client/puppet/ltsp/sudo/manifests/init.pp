class sudo {
  include config::logins,
          packages

  file {
    '/etc/sudoers':
      content => template('sudo/sudoers'),
      mode    => 440,
      require => Package['sudo'];

    '/etc/sudoers.d/ltspadmins':
      content => template('sudo/sudoers.d/ltspadmins'),
      mode    => 440,
      require => File['/etc/sudoers'];
  }

  Package <| title == "sudo" |>
}
