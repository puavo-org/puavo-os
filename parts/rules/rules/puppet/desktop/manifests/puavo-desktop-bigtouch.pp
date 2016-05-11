class desktop::puavo-desktop-bigtouch {
  include desktop::dconf,
          gnome_shell_extensions,
          packages

  file {
    '/etc/dconf/db/puavo-desktop-bigtouch.d':
      ensure => directory;

    '/etc/dconf/db/puavo-desktop-bigtouch.d/profile':
      content => template('desktop/puavo-desktop-bigtouch/profile'),
      notify  => Exec['update dconf'];
  }

}
