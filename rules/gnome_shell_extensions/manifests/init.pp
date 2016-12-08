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
    , 'bigtouch-ux@puavo.org'
    , 'bottompanel@tmoer93'
    , 'extend-left-box2@linuxdeepin.com'
    , 'hide-activities-button@gnome-shell-extensions.bookmarkd.xyz'
    , 'Move_Clock@rmy.pobox.com'
    , 'Panel_Favorites@rmy.pobox.com'
    , 'webmenu@puavo.org'
    , 'window-list-mod@puavo.org' ]:
      ;
  }

  Package <| title == gnome-shell-extensions |>
}
