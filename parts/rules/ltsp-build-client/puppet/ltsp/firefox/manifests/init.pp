class firefox {
  include firefox

  # Firefox configuration system is still a mess... if there really is a more
  # straightforward way, I would like to hear about it.
  file {
    '/etc/firefox/puavodesktop.js':
      content => template('firefox/puavodesktop.js'),
      require => Package['firefox'];

    '/etc/firefox/syspref.js':
      content => template('firefox/syspref.js'),
      require => File['/usr/lib/firefox/firefox-puavodesktop.js'];

    '/usr/lib/firefox/firefox-puavodesktop.js':
      content => template('firefox/firefox-puavodesktop.js'),
      require => File['/etc/firefox/puavodesktop.js'];
  }

  Package <| title == firefox |>
}
