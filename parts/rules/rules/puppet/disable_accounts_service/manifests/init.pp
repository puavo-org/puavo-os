class disable_accounts_service {
  include dpkg

  dpkg::simpledivert {
    '/usr/share/dbus-1/system-services/org.freedesktop.Accounts.service':
      ;
  }
}
