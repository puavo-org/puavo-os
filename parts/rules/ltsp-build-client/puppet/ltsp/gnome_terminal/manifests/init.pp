class gnome_terminal {
  require packages

  exec {
    "set as x-terminal-emulator":
      command => "/usr/bin/update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal.wrapper",
      require => Package['gnome-terminal'],
      unless  => "/usr/bin/update-alternatives --query x-terminal-emulator | /bin/grep -qx 'Value: /usr/bin/gnome-terminal.wrapper'";
  }

  Package <| title == gnome-terminal |>
}
