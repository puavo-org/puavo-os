class bootserver_helpers {
  file {
    '/usr/local/bin/puavo-bootserver-list-clients':
      content => template('bootserver_helpers/puavo-bootserver-list-clients'),
      mode    => 0755;
  }
}
