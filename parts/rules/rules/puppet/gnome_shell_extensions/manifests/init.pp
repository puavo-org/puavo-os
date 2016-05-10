class gnome_shell_extensions {
  include packages

  file {
    '/usr/share/gnome-shell/extensions/hide-panel@puavo.org':
      source  => 'puppet:///modules/gnome_shell_extensions/hide-panel',
      recurse => true,
      require => Package['gnome-shell-extensions'];
  }

  Package <| title == gnome-shell-extensions |>
}
