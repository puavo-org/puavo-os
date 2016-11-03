class desktop::dconf::desktopbackgroundlock {
  include ::desktop::dconf

  file {
    [ '/etc/dconf/db/desktopbackgroundlock.d'
    , '/etc/dconf/db/desktopbackgroundlock.d/locks' ]:
      ensure => directory;

    '/etc/dconf/db/desktopbackgroundlock.d/locks/desktopbackgroundlock':
      content => "/org/gnome/desktop/background/picture-uri\n",
      notify  => Exec['update dconf'];
  }
}
