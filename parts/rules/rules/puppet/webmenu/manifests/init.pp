class webmenu {
  include dpkg,
          packages

  File { require => Package['webmenu'], }
  file {
    '/etc/puavo-external-files-actions.d/webmenu':
      require => Package['puavo-ltsp-client'],
      content => template('webmenu/puavo-external-files-actions.d/webmenu'),
      mode    => 755;

    [ '/etc/webmenu'
    , '/etc/webmenu/desktop.d'
    , '/etc/webmenu/personally-administered-device'
    , '/etc/webmenu/tab.d' ]:
      ensure => directory;

    '/etc/webmenu/config.json':
      content => template('webmenu/config.json');

    '/etc/webmenu/desktop.d/default-overrides.yaml':
      content => template('desktop.d/default-overrides.yaml');

    '/etc/webmenu/menu.yaml':
      content => template('webmenu/menu.yaml');

    '/etc/webmenu/personally-administered-device/config.json':
      content => template('webmenu/personally-administered-device-config.json');

    '/etc/webmenu/personally-administered-device/menu.yaml':
      content => template('webmenu/personally-administered-device-menu.yaml');

    '/etc/webmenu/tab.d/ops.yaml':
      content => template('tab.d/ops.yaml');

    '/etc/xdg/autostart/webmenu.desktop':
      content => template('webmenu/webmenu.desktop'),
      require => File['/usr/local/bin/puavo-webmenu'];

    '/usr/local/bin/puavo-webmenu':
      content => template('webmenu/puavo-webmenu'),
      mode    => 755;
  }

  Package <| title == webmenu |>
}
