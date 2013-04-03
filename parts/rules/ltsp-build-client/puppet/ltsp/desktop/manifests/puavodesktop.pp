class desktop::puavodesktop {
  include desktop::dconf::puavodesktop,
          # desktop::mimedefaults,      # XXX needs more testing
          packages,
          webmenu

  file {
    '/etc/dconf/db/puavodesktop.d/locks/session_locks':
      content => template('desktop/dconf_session_locks'),
      notify  => Exec['update dconf'];

    '/etc/dconf/db/puavodesktop.d/session_profile':
      content => template('desktop/dconf_session_profile'),
      notify  => Exec['update dconf'],
      require => [ Package['faenza-icon-theme']
                 , Package['liitu-themes']
                 , Package['webmenu'] ];
  }

  Package <| (title == faenza-icon-theme)
          or (title == liitu-themes)      |>
}
