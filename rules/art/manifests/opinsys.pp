class art::opinsys {
  file {
    '/usr/share/opinsys-art':
      ensure => directory;

    '/usr/share/opinsys-art/logo16.png':
      source => 'puppet:///modules/plymouth/theme/opinsys/logo16.png';

    '/usr/share/opinsys-art/logo.png':
      source => 'puppet:///modules/plymouth/theme/opinsys/logo.png';

    '/usr/share/opinsys-art/opinsys-applet-idle.png':
      source => 'puppet:///modules/art/opinsys/opinsys-applet-idle.png';

    '/usr/share/opinsys-art/opinsys-applet-remote-access-active.png':
      source => 'puppet:///modules/art/opinsys/opinsys-applet-remote-access-active.png';

    '/usr/share/opinsys-art/opinsys-support-info-fi.png':
      source => 'puppet:///modules/art/opinsys/opinsys-support-info-fi.png';
  }
}
