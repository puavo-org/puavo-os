class desktop::dconf::turn_off_xrandrplugin {
  include ::desktop::dconf

  file {
    '/etc/dconf/db/turn_off_xrandrplugin.d':
      ensure => directory;

    '/etc/dconf/db/turn_off_xrandrplugin.d/turn_off_xrandrplugin':
      content => template('desktop/dconf_turn_off_xrandrplugin_profile'),
      notify  => Exec['update dconf'];
  }
}
