class gnome_shell_extensions {
  include ::dpkg
  include ::packages

  dpkg::simpledivert {
    '/usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/metadata.json':
      require => Package['gnome-shell-extension-user-theme'];
  }

  define add_extension () {
    $extension = $title

    file {
      "/usr/share/gnome-shell/extensions/${extension}/":
	recurse => true,
	require => Package['gnome-shell-extensions'],
	source  => "puppet:///modules/gnome_shell_extensions/${extension}";
    }
  }

  @::gnome_shell_extensions::add_extension {
    'quickoverview@puavo.org':
      require => [ ::Themes::Iconlink['scalable/places/puavo-base-user-desktop.svg']
                 , ::Themes::Iconlink['scalable/places/puavo-hover-user-desktop.svg' ] ];

    'show-desktop-applet@valent-in':
      require => ::Themes::Iconlink['scalable/apps/puavo-multitasking-view.svg'];

    [ 'appindicatorsupport@rgcjonas.gmail.com'
    , 'dash-to-panel@jderose9.github.com'
    , 'hide-overview-search-entry@puavo.org'
    , 'hostinfo@puavo.org'
    , 'Move_Clock@rmy.pobox.com'
    , 'panel-to-bottom@davron'
    , 'puavomenu@puavo.org'
    , 'quick-settings-tweaks@qwreey'
    , 'screenkeyboardcontroller@puavo.org' ]:
      ;

    'user-theme@gnome-shell-extensions.gcampax.github.com':
      require => ::Dpkg::Simpledivert['/usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/metadata.json'];
  }

  Package <|
      title == gnome-shell-extensions
   or title == gnome-shell-extension-user-theme
  |>
}
