class bootserver_inetd {
  file {
    '/etc/inetd.conf':
      content => template('bootserver_inetd/inetd.conf');
  }
}
