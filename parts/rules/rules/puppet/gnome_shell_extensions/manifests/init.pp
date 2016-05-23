class gnome_shell_extensions {
  include packages

  file {
    '/usr/share/gnome-shell/extensions/bigtouch-ux@puavo.org':
      source  => 'puppet:///modules/gnome_shell_extensions/bigtouch-ux',
      recurse => true,
      require => Package['gnome-shell-extensions'];

    '/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com':
      source  => 'puppet:///modules/gnome_shell_extensions/dash-to-dock',
      recurse => true,
      require => Package['gnome-shell-extensions'];
  }

  Package <| title == gnome-shell-extensions |>
}
