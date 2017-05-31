class nss {
  include ::packages

  file {
    '/etc/nsswitch.conf':
      require => Package['libnss-extrausers'],
      source  => 'puppet:///modules/nss/nsswitch.conf';
  }

  Package <| title == libnss-extrausers |>
}
