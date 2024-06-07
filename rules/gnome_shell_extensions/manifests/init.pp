class gnome_shell_extensions {
  include ::dconf::schemas
  include ::desktop::dconf
  include ::packages
  include ::puavo_conf
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

  define screenkeyboardcontroller_dconf () {
    $mode = $title

    file {
      [ "/etc/dconf/db/screenkeyboardcontroller_${mode}.d"
      , "/etc/dconf/db/screenkeyboardcontroller_${mode}.d/locks" ]:
        ensure => directory;

    "/etc/dconf/db/screenkeyboardcontroller_${mode}.d/locks/screenkeyboardcontroller_${mode}_locks":
      content => template('gnome_shell_extensions/dconf_screenkeyboardcontroller_locks'),
      notify  => Exec['update dconf'],
      require => ::Dconf::Schemas::Schema['org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml'];

    "/etc/dconf/db/screenkeyboardcontroller_${mode}.d/locks/screenkeyboardcontroller_${mode}_profile":
      content => template('gnome_shell_extensions/dconf_screenkeyboardcontroller_profile'),
      notify  => Exec['update dconf'],
      require => ::Dconf::Schemas::Schema['org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml'];
    }
  }

  ::gnome_shell_extensions::add_extension {
    'quickoverview@kirby_33@hotmail.fr':
      require => [ ::Themes::Iconlink['scalable/places/puavo-base-user-desktop.svg']
                 , ::Themes::Iconlink['scalable/places/puavo-hover-user-desktop.svg' ] ];

    'show-desktop@l300lvl.tk':
      require => ::Themes::Iconlink['scalable/apps/puavo-multitasking-view.svg'];

    [ 'appindicatorsupport@rgcjonas.gmail.com'
    , 'bottompanel@tmoer93'
    , 'dash-to-panel@jderose9.github.com'
    , 'ding@rastersoft.com'
    , 'hide-overview-search-entry@puavo.org'
    , 'hostinfo@puavo.org'
    , 'Move_Clock@rmy.pobox.com'
    , 'puavomenu@puavo.org'
    , 'quick-settings-tweaks@qwreey'
    , 'screenkeyboardcontroller@puavo.org'
    , 'user-theme@gnome-shell-extensions.gcampax.github.com' ]:
      ;
  }

  file {
    '/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/createThumbnail.js':
      mode    => '0755',
      require => ::Gnome_shell_extensions::Add_extension['ding@rastersoft.com'],
      source  => 'puppet:///modules/gnome_shell_extensions/ding@rastersoft.com/app/createThumbnail.js';

    '/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/ding.js':
      mode    => '0755',
      require => ::Gnome_shell_extensions::Add_extension['ding@rastersoft.com'],
      source  => 'puppet:///modules/gnome_shell_extensions/ding@rastersoft.com/app/ding.js';
  }

  ::puavo_conf::definition {
    'screenkeyboardcontroller.json':
      source => 'puppet:///modules/gnome_shell_extensions/screenkeyboardcontroller.json';
  }

  ::dconf::schemas::schema {
    'org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml':
      srcfile => 'puppet:///modules/gnome_shell_extensions/screenkeyboardcontroller@puavo.org/schemas/org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml';
  }

  ::gnome_shell_extensions::screenkeyboardcontroller_dconf {
    [ 'auto_hide'
    , 'do_nothing'
    , 'force_hide' ]:
      ;
  }

  Package <| title == gnome-shell-extensions |>
}
