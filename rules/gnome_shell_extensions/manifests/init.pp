class gnome_shell_extensions {
  include ::dconf::schemas
  include ::packages

  define add_extension () {
    $extension = $title

    file {
      "/usr/share/gnome-shell/extensions/${extension}/":
	recurse => true,
	require => Package['gnome-shell-extensions'],
	source  => "puppet:///modules/gnome_shell_extensions/${extension}";
    }
  }

  ::gnome_shell_extensions::add_extension {
    'hide-panel-power-indicator@puavo.org':
      require => ::Dconf::Schemas::Schema['org.gnome.puavo.gschema.xml'];
  }

  ::gnome_shell_extensions::add_extension {
    [ 'appindicatorsupport@rgcjonas.gmail.com'
    , 'audio-menu-modifier@puavo.org'
    , 'bottompanel@tmoer93'
    , 'dash-to-panel@jderose9.github.com'
    , 'extend-left-box2@linuxdeepin.com'
    , 'hide-activities-button@gnome-shell-extensions.bookmarkd.xyz'
    , 'hide-aggregatemenu-session-buttons@puavo.org'
    , 'hide-dash@xenatt.github.com'
    , 'hostinfo@puavo.org'
    , 'Move_Clock@rmy.pobox.com'
    , 'Panel_Favorites@rmy.pobox.com'
    , 'TopIcons@phocean.net'
    , 'webmenu@puavo.org'
    , 'window-list-mod@puavo.org' ]:
      ;
  }

  Package <| title == gnome-shell-extensions |>
}
