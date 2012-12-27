class firefox {
  include firefox

  file {
    '/etc/firefox/syspref.js':
      content => template('firefox/syspref.js'),
      require => Package['firefox'];
  }

  Package <| title == firefox |>
}
