class puavo_desktop_applet {
  # XXX dependencies?

  file {
    '/etc/xdg/autostart/puavo-desktop-applet.desktop':
      require => File['/usr/local/bin/puavo-desktop-applet'],
      source  => 'puppet:///modules/puavo_desktop_applet/puavo-desktop-applet.desktop';

    '/usr/local/bin/puavo-desktop-applet':
      mode   => '0755',
      source => 'puppet:///modules/puavo_desktop_applet/puavo-desktop-applet';
  }
}
