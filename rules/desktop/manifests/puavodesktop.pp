class desktop::puavodesktop {
  include ::art
  include ::dconf
  include ::desktop::autologin
  include ::desktop::dconf::disable_lidsuspend
  include ::desktop::dconf::disable_suspend
  include ::desktop::dconf::exammode
  include ::desktop::dconf::laptop
  include ::desktop::dconf::nokeyboard
  include ::desktop::dconf::puavodesktop
  include ::desktop::dconf::puavo_ers
  include ::desktop::mimedefaults
  include ::gnome_shell_extensions::puavodesktop
  include ::gnome_shell_helper
  include ::packages
  include ::puavomenu
  include ::puavo_suspend_tricks
  include ::puavo_sysinfo_collector
  include ::themes

  ::dconf::configfile {
    'dconf puavo-desktop locks':
      content => template('desktop/dconf_session_locks'),
      dbname  => 'puavo-desktop',
      subpath => 'locks/session_locks';

    'dconf puavo-desktop profile':
      content => template('desktop/dconf_session_profile'),
      dbname  => 'puavo-desktop',
      subpath => 'session_profile',
      require => [ File['/usr/share/puavo-art']
                 , Package['faenza-icon-theme']
                 , Package['puavomenu'] ];
  }

  # overwrite /etc/profile with our custom version
  file {
    '/etc/profile':
      source => 'puppet:///modules/desktop/profile',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
  }

  Package <| title == faenza-icon-theme
          or title == puavomenu |>
}
