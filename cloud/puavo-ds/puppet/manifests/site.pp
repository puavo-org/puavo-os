class kerberos {
  file { "/etc/krb5kdc":
    path => "/etc/krb5kdc/",
    owner => root,
    group => root,
    mode => 600,
    source => "puppet:///files/etc/krb5kdc/",
    recurse => true
  }

  file { "/etc/krb5.conf":
    path => "/etc/krb5.conf",
    owner => root,
    group => root,
    mode => 644,
    source => "puppet:///files/etc/krb5.conf",
    recurse => true
  }

  file { "/etc/krb5.secrets":
    path => "/etc/krb5.secrets",
    owner => root,
    group => root,
    mode => 600,
    source => "puppet:///files/etc/krb5.secrets",
    recurse => true
  }

  file { "/etc/default/krb5-kdc":
    path => "/etc/default/krb5-kdc",
    owner => root,
    group => root,
    mode => 644,
    source => "puppet:///files/etc/default/krb5-kdc",
  }

  file { "/usr/local/sbin/puavo_update_kdc_settings":
    path => "/usr/local/sbin/puavo_update_kdc_settings",
    owner => root,
    group => root,
    mode => 755,
    source => "puppet:///files/usr/local/sbin/puavo_update_kdc_settings"
  }

  file { "/etc/init.d/puavo_kadmind":
    path => "/etc/init.d/puavo_kadmind",
    owner => root,
    group => root,
    mode => 755,
    source => "puppet:///files/etc/init.d/puavo_kadmind"
  }

  exec { "/usr/local/sbin/puavo_update_kdc_settings":
    subscribe => File["/etc/krb5kdc", "/etc/krb5.conf", "/etc/krb5.secrets", "/etc/default/krb5-kdc", "/usr/local/sbin/puavo_update_kdc_settings"],
    refreshonly => true,
    require => File["/usr/local/sbin/puavo_update_kdc_settings"]
  }
}

node default { include kerberos }
