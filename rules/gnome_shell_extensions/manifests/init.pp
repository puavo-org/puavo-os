class gnome_shell_extensions {
  include ::packages

  define add_extension () {
    $extension = $title

    file {
      "/usr/share/gnome-shell/extensions/${extension}":
	recurse => true,
	require => Package['gnome-shell-extensions'],
	source  => "puppet:///modules/gnome_shell_extensions/${extension}";
    }
  }

  ::gnome_shell_extensions::add_extension {
    [ 'appindicatorsupport@rgcjonas.gmail.com'
    , 'audio-switcher@AndresCidoncha'
    , 'bigtouch-ux@puavo.org'
    , 'bottompanel@tmoer93'
    , 'extend-left-box2@linuxdeepin.com'
    , 'hide-activities-button@gnome-shell-extensions.bookmarkd.xyz'
    , 'hide-dash@xenatt.github.com'
    , 'Move_Clock@rmy.pobox.com'
    , 'Panel_Favorites@rmy.pobox.com'
    , 'TopIcons@phocean.net'
    , 'webmenu@puavo.org'
    , 'window-list-mod@puavo.org' ]:
      ;
  }

  Package <| title == gnome-shell-extensions |>
}
