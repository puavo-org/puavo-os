class desktop::puavo_desktop_webkiosk {
  include ::desktop::dconf::puavodesktop

  file {
    '/etc/dconf/db/puavo-webkiosk':
      ensure  => symlink,
      require => File['/etc/dconf/db/puavo-desktop.d'],
      target  => 'puavo-desktop';

    '/etc/dconf/db/puavo-webkiosk.d':
      ensure  => symlink,
      require => [ Exec['update dconf']
                 , File['/etc/dconf/db/puavo-desktop.d'] ],
      target  => 'puavo-desktop.d';
  }
}
