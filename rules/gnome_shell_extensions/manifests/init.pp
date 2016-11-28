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

  # XXX disabled 'TaskBar@zpydr', triggers a bug in some hosts when used with
  # XXX user-theme@gnome-shell-extensions.gcampax.github.com

  ::gnome_shell_extensions::add_extension {
    [ 'appindicatorsupport@rgcjonas.gmail.com'
    , 'bigtouch-ux@puavo.org'
    , 'bottompanel@tmoer93'
    , 'Move_Clock@rmy.pobox.com'
    , 'webmenu@puavo.org'
    , 'window-list-mod@vagonpop.gmail.com' ]:
      ;
  }

  Package <| title == gnome-shell-extensions |>
}
