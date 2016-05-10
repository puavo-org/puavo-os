class desktop::puavo-bats {
  include desktop::dconf,
          gnome_shell_extensions,
          packages

  file {
    '/etc/dconf/db/puavo-bats.d':
      ensure => directory;

    '/etc/dconf/db/puavo-bats.d/extensions':
      content => template('desktop/puavo-bats/extensions'),
      notify  => Exec['update dconf'];
  }

}
