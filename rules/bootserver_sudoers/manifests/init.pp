class bootserver_sudoers {
  file {
    '/etc/sudoers':
      content => template('bootserver_sudoers/sudoers'),
      mode    => 440;
  }
}
