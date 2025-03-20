class gnome_shell_extensions::screenkeyboardcontroller {
  include ::dconf::schemas
  include ::gnome_shell_extensions
  include ::puavo_conf

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

    "/etc/dconf/db/screenkeyboardcontroller_${mode}.d/screenkeyboardcontroller_${mode}_profile":
      content => template('gnome_shell_extensions/dconf_screenkeyboardcontroller_profile'),
      notify  => Exec['update dconf'],
      require => ::Dconf::Schemas::Schema['org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml'];
    }
  }

  ::dconf::schemas::schema {
    'org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml':
      srcfile => 'puppet:///modules/gnome_shell_extensions/screenkeyboardcontroller@puavo.org/schemas/org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml';
  }

  ::gnome_shell_extensions::puavodesktop::screenkeyboardcontroller_dconf {
    [ 'auto_hide'
    , 'do_nothing'
    , 'force_hide' ]:
      ;
  }

  ::puavo_conf::definition {
    'puavo-screenkeyboardcontroller.json':
      source => 'puppet:///modules/gnome_shell_extensions/puavo-screenkeyboardcontroller.json';
  }
}
