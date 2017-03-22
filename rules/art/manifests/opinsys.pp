class art::opinsys {
  file {
    '/usr/share/opinsys-art':
      ensure => directory;

    '/usr/share/opinsys-art/logo16.png':
      source  => 'puppet:///modules/plymouth/theme/opinsys/logo16.png';

    '/usr/share/opinsys-art/logo.png':
      source  => 'puppet:///modules/plymouth/theme/opinsys/logo.png';
  }
}
