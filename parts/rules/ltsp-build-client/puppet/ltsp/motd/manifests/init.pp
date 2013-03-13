class motd {
  file {
    '/etc/update-motd.d/95-puavo-information':
      content => template('motd/95-puavo-information'),
      mode    => 755;
  }
}
