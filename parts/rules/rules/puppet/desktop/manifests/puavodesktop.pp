class desktop::puavodesktop {
  include desktop::dconf::desktopbackgroundlock,
          desktop::dconf::disable_lidsuspend,
          desktop::dconf::disable_suspend,
          desktop::dconf::laptop,
          desktop::dconf::nokeyboard,
          desktop::dconf::puavodesktop,
          desktop::dconf::turn_off_xrandrplugin,
          desktop::enable_indicator_power_service,
          desktop::mimedefaults,
          packages
          # webmenu	# XXX needs packaging for Debian

  file {
    '/etc/dconf/db/puavodesktop.d/locks/session_locks':
      content => template('desktop/dconf_session_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/puavodesktop.d/session_profile':
      content => template('desktop/dconf_session_profile'),
      notify  => Exec['update dconf'],
      require => [ Package['faenza-icon-theme'] ];
                 # , Package['light-themes'] ];	# XXX needs packaging
                 # , Package['webmenu'] ];	# XXX for Debian

    # webmenu takes care of the equivalent functionality
    '/etc/xdg/autostart/indicator-session.desktop':
      ensure  => absent,
      require => Package['indicator-session'];

    '/usr/share/icons/Faenza/apps/24/calendar.png':
      ensure  => link,
      require => Package['faenza-icon-theme'],
      target  => 'evolution-calendar.png';
  }

  Package <| title == faenza-icon-theme
          or title == indicator-session
          or title == light-themes
          or title == webmenu           |>
}
