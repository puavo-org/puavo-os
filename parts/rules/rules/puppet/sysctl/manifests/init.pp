class sysctl {
  include packages

  file {
    '/etc/sysctl.d/88-puavo.conf':
      content => template('sysctl/conf'),
      mode    => 0644,
      require => Package['procps'];
  }

  Package <| title == procps |>

}
