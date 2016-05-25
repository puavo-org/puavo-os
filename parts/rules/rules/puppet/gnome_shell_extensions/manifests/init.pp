class gnome_shell_extensions {
  include packages

  file {
    '/usr/share/gnome-shell/extensions/bigtouch-ux@puavo.org':
      source  => 'puppet:///modules/gnome_shell_extensions/bigtouch-ux',
      recurse => true,
      require => Package['gnome-shell-extensions'];

  }

  Package <| title == gnome-shell-extensions |>
}
