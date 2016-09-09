class desktop::puavodesktop {
  include desktop::dconf::desktopbackgroundlock,
          desktop::dconf::disable_lidsuspend,
          desktop::dconf::disable_suspend,
          desktop::dconf::laptop,
          desktop::dconf::nokeyboard,
          desktop::dconf::puavodesktop,
          desktop::dconf::turn_off_xrandrplugin,
          # desktop::enable_indicator_power_service,	# XXX needs fixing
          desktop::mimedefaults,
          packages,
          webmenu

  file {
    '/etc/dconf/db/puavo-desktop.d/locks/session_locks':
      content => template('desktop/dconf_session_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/puavo-desktop.d/session_profile':
      content => template('desktop/dconf_session_profile'),
      notify  => Exec['update dconf'],
      require => [ Package['faenza-icon-theme']
		 , Package['webmenu'] ];
                 # , Package['light-themes'] ];	# XXX needs packaging

    # webmenu takes care of the equivalent functionality
    '/etc/xdg/autostart/indicator-session.desktop':
      ensure  => absent,
      require => Package['indicator-session'];

    '/usr/share/icons/Faenza/apps/24/calendar.png':
      ensure  => link,
      require => Package['faenza-icon-theme'],
      target  => 'evolution-calendar.png';

    '/usr/share/backgrounds/puavo-art':
      source  => 'puppet:///modules/desktop/art',
      recurse => true;

    # add this link so that Gnome backgrounds show up in Cinnamon settings
    '/usr/share/cinnamon-background-properties':
      ensure => link,
      target => 'gnome-background-properties';
  }

  Package <| title == faenza-icon-theme
          or title == indicator-session
          or title == light-themes
          or title == webmenu |>
}
