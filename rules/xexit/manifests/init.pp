class xexit {
  include packages

  file {
    '/etc/Xexit.d/01examplexexit':
      ensure  => absent,
      require => Package['xexit'];

    '/etc/Xexit.d/01-kill-desktop-session':
      content => template('xexit/01-kill-desktop-session'),
      require => Package['xexit'];
  }

  Package <| title == xexit |>
}
