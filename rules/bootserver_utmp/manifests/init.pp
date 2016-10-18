class bootserver_utmp {

  define enable {
    exec {
      "/usr/local/sbin/enable-utmp-log /var/log/$title":
        require => File['/usr/local/sbin/enable-utmp-log'],
        creates => "/var/log/$title";
    }
  }

  file {
    '/usr/local/sbin/enable-utmp-log':
      content => template('bootserver_utmp/enable-utmp-log'),
      mode    => 755;
  }

  bootserver_utmp::enable {
    [ "btmp"
    , "wtmp"
    , "lastlog" ]:
      ;
  }
}
