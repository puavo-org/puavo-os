class libdvdcss {
  include ::packages

  exec {
    '/usr/lib/libdvd-pkg/b-i_libdvdcss.sh':
      creates => '/usr/lib/x86_64-linux-gnu/libdvdcss.so.2',
      require => Package['libdvd-pkg'];
  }

  Package <| title == libdvd-pkg |>
}
