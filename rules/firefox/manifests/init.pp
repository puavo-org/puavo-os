class firefox {
  include ::packages

  # Firefox configuration system is still a mess... if there really is a more
  # straightforward way, I would like to hear about it.
  file {
    '/etc/firefox/puavodesktop.js':
      content => template('firefox/puavodesktop.js'),
      require => Package['firefox'];

    '/etc/firefox/syspref.js':
      content => template('firefox/syspref.js'),
      require => File['/usr/lib/firefox/firefox-puavodesktop.js'];

    '/etc/X11/Xsession.d/48puavo-set-apiserver-envvar':
      content => template('firefox/48puavo-set-apiserver-envvar');

    '/usr/lib/firefox/firefox-puavodesktop.js':
      content => template('firefox/firefox-puavodesktop.js'),
      require => File['/etc/firefox/puavodesktop.js'];

    '/etc/puavo-external-files-actions.d/firefox':
      content => template('firefox/puavo-external-files-actions.d/firefox'),
      mode    => '0755',
      require => Package['puavo-ltsp-client'];
  }

  Package <| title == firefox
          or title == puavo-ltsp-client |>
}
