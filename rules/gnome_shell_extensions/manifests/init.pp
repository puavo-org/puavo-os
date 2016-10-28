class gnome_shell_extensions {
  include packages

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
    , 'bottom-panel@sharats.me' ]:
      ;
  }

  Package <| title == gnome-shell-extensions |>
}
