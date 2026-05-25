class gnome_shell_extensions::screenkeyboardcontroller {
  include ::dconf
  include ::dconf::schemas
  include ::gnome_shell_extensions
  include ::puavo_conf

  define dconf () {
    $mode = $title

    file {
      [ "/etc/dconf/db/screenkeyboardcontroller_${mode}.d"
      , "/etc/dconf/db/screenkeyboardcontroller_${mode}.d/locks" ]:
        ensure => directory;
    }

    ::dconf::configfile {
      "dconf screenkeyboardcontroller_${mode} locks":
        content => template('gnome_shell_extensions/dconf_screenkeyboardcontroller_locks'),
        dbname  => "screenkeyboardcontroller_${mode}",
        require => ::Dconf::Schemas::Schema['org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml'],
        subpath => "locks/screenkeyboardcontroller_${mode}_locks";

      "dconf screenkeyboardcontroller_${mode} profile":
        content => template('gnome_shell_extensions/dconf_screenkeyboardcontroller_profile'),
        dbname  => "screenkeyboardcontroller_${mode}",
        require => ::Dconf::Schemas::Schema['org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml'],
        subpath => "screenkeyboardcontroller_${mode}_profile";
    }
  }

  ::dconf::schemas::schema {
    'org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml':
      srcfile => 'puppet:///modules/gnome_shell_extensions/screenkeyboardcontroller@puavo.org/schemas/org.gnome.shell.extensions.screenkeyboardcontroller.gschema.xml';
  }

  ::gnome_shell_extensions::screenkeyboardcontroller::dconf {
    [ 'auto_hide', 'do_nothing', 'force_hide' ]: ;
  }

  ::puavo_conf::definition {
    'puavo-screenkeyboardcontroller.json':
      source => 'puppet:///modules/gnome_shell_extensions/puavo-screenkeyboardcontroller.json';
  }
}
