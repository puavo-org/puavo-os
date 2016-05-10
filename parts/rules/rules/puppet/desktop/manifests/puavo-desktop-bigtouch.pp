class desktop::puavo-desktop-bigtouch {
  include desktop::dconf,
          gnome_shell_extensions,
          packages

  file {
    '/etc/dconf/db/puavo-desktop-bigtouch.d':
      ensure => directory;

    '/etc/dconf/db/puavo-desktop-bigtouch.d/extensions':
      content => template('desktop/puavo-desktop-bigtouch/extensions'),
      notify  => Exec['update dconf'];
  }

}
