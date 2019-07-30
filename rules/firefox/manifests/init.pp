class firefox {
  include ::packages
  include ::puavo_pkg::packages

  # Firefox configuration system is still a mess... if there really is a more
  # straightforward way, I would like to hear about it.
  file {
    '/etc/firefox':
      ensure => directory;

    '/etc/firefox/puavodesktop.js':
      content => template('firefox/puavodesktop.js');

    '/etc/firefox/syspref.js':
      content => template('firefox/syspref.js'),
      require => Puavo_pkg::Install['firefox'];

    '/etc/puavo-external-files-actions.d/firefox':
      content => template('firefox/puavo-external-files-actions.d/firefox'),
      mode    => '0755',
      require => Package['puavo-ltsp-client'];

    '/etc/X11/Xsession.d/48puavo-set-apiserver-envvar':
      content => template('firefox/48puavo-set-apiserver-envvar');
  }

  Package <| title == puavo-ltsp-client |>
  Puavo_pkg::Install <| title == firefox |>
}
