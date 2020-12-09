class desktop::puavodesktop {
  include ::art
  include ::desktop::dconf::disable_lidsuspend
  include ::desktop::dconf::disable_suspend
  include ::desktop::dconf::laptop
  include ::desktop::dconf::nokeyboard
  include ::desktop::dconf::puavodesktop
  include ::desktop::dconf::puavo_ers
  # include ::desktop::enable_indicator_power_service	# XXX needs fixing
  include ::desktop::mimedefaults
  include ::gnome_shell_extensions
  include ::gnome_shell_helper
  include ::nodm
  include ::packages
  include ::puavomenu
  include ::puavo_sysinfo_collector
  include ::themes

  file {
    '/etc/dconf/db/puavo-desktop.d/locks/session_locks':
      content => template('desktop/dconf_session_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/puavo-desktop.d/session_profile':
      content => template('desktop/dconf_session_profile'),
      notify  => Exec['update dconf'],
      require => [ File['/usr/share/puavo-art']
                 , Package['faenza-icon-theme']
		 , Package['puavomenu'] ];
                 # , Package['light-themes'] ];	# XXX needs packaging
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
          or title == light-themes
          or title == puavomenu |>
}
