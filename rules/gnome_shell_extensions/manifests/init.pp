class gnome_shell_extensions {
  include packages

  file {
    '/usr/share/gnome-shell/extensions/bigtouch-ux@puavo.org':
      recurse => true,
      require => Package['gnome-shell-extensions'],
      source  => 'puppet:///modules/gnome_shell_extensions/bigtouch-ux@puavo.org';

  }

  Package <| title == gnome-shell-extensions |>
}
