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
      content => template('webmenu/desktop.d/default-overrides.yaml'),
      require => [ Package['gnome-themes-extras'], Package['webmenu'], ];

    '/etc/webmenu/menu.yaml':
      content => template('webmenu/menu.yaml');

    '/etc/webmenu/personally-administered-device/config.json':
      content => template('webmenu/personally-administered-device-config.json');

    '/etc/webmenu/tab.d/ops.yaml':
      content => template('webmenu/tab.d/ops.yaml'),
      require => # XXX no Debian package for breathe-icon-theme
                 [ Package['faenza-icon-theme']
                 , Package['oxygen-icon-theme']
                 , Package['tuxpaint-stamps-default']
                 , Package['webmenu'] ];

    '/etc/xdg/autostart/webmenu.desktop':
      content => template('webmenu/webmenu.desktop'),
      require => File['/usr/local/bin/puavo-webmenu'];

    '/usr/local/bin/puavo-webmenu':
      content => template('webmenu/puavo-webmenu'),
      mode    => 755;
  }

  Package <|
       title == breathe-icon-theme
    or title == faenza-icon-theme
    or title == oxygen-icon-theme
    or title == tuxpaint-stamps-default
    or title == webmenu
  |>
}
