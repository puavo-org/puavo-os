class bootserver_samba {
  file {
    '/etc/pam.d/samba':
      content => template('bootserver_samba/pam.samba'),
      mode    => 644;
  }

  exec {
    '/usr/sbin/puavo-init-samba-server':
      creates => '/etc/samba/cifs.keytab';
  }
}
