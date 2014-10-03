class disable_gnome_keyring_autostart {
  include dpkg,
          packages

  Dpkg::Simpledivert { require => Package['gnome-keyring'], }
  dpkg::simpledivert {
    [ '/etc/xdg/autostart/gnome-keyring-gpg.desktop'
    , '/etc/xdg/autostart/gnome-keyring-pkcs11.desktop'
    , '/etc/xdg/autostart/gnome-keyring-secrets.desktop'
    , '/etc/xdg/autostart/gnome-keyring-ssh.desktop'
    , '/usr/share/dbus-1/services/org.gnome.keyring.PrivatePrompter.service'
    , '/usr/share/dbus-1/services/org.gnome.keyring.SystemPrompter.service' ]:
      ;
  }

  Package <| title == gnome-keyring |>
}
