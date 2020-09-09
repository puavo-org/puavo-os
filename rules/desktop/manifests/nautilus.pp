class desktop::nautilus {
  include ::dpkg
  include ::packages

  $nautilus_desktop_path = '/usr/share/applications/org.gnome.Nautilus.desktop'

  dpkg::simpledivert { $nautilus_desktop_path: ; }

  # we want to change Nautilus icon to "user-home", no other changes
  file {
    $nautilus_desktop_path:
      require => Dpkg::Divert[$nautilus_desktop_path],
      source  => 'puppet:///modules/desktop/org.gnome.Nautilus.desktop';
  }

  Package <| title == nautilus |>
}
