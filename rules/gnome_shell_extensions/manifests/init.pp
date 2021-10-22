class gnome_shell_extensions {
  include ::dconf::schemas
  include ::packages
  include ::themes

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

    'quickoverview@kirby_33@hotmail.fr':
      require => [ ::Themes::Iconlink['scalable/places/puavo-base-user-desktop.svg']
                 , ::Themes::Iconlink['scalable/places/puavo-hover-user-desktop.svg' ] ];

    'show-desktop@l300lvl.tk':
      require => ::Themes::Iconlink['scalable/apps/puavo-multitasking-view.svg'];

    [ 'appindicatorsupport@rgcjonas.gmail.com'
    , 'audio-menu-modifier@puavo.org'
    , 'bottompanel@tmoer93'
    , 'dash-to-panel@jderose9.github.com'
    , 'ding@rastersoft.com'
    , 'hide-activities-button@gnome-shell-extensions.bookmarkd.xyz'
    , 'hide-overview-search-entry@puavo.org'
    , 'hostinfo@puavo.org'
    , 'LogOutButton@kyle.aims.ac.za'
    , 'Move_Clock@rmy.pobox.com'
    , 'nohotcorner@azuri.free.fr'
    , 'puavomenu@puavo.org'
    , 'TopIcons@phocean.net'
    , 'uparrows@puavo.org'
    , 'window-list-mod@puavo.org' ]:
      ;
  }

  file {
    '/usr/share/gnome-shell/extensions/ding@rastersoft.com/createThumbnail.js':
      mode    => '0755',
      require => ::Gnome_shell_extensions::Add_extension['ding@rastersoft.com'],
      source  => 'puppet:///modules/gnome_shell_extensions/ding@rastersoft.com/createThumbnail.js';

    '/usr/share/gnome-shell/extensions/ding@rastersoft.com/ding.js':
      mode    => '0755',
      require => ::Gnome_shell_extensions::Add_extension['ding@rastersoft.com'],
      source  => 'puppet:///modules/gnome_shell_extensions/ding@rastersoft.com/ding.js';
  }


  Package <| title == gnome-shell-extensions |>
}
