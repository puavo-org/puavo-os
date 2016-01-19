class disable_update_notifications {
  require packages

  file {
    [ '/etc/update-motd.d/90-updates-available'
    , '/etc/update-motd.d/98-reboot-required'
    , '/etc/update-motd.d/98-fsck-at-reboot' ]:
      ensure => absent;
  }
}
