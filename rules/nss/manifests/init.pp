class nss {
  include ::packages

  file {
    '/etc/nsswitch.conf':
      require => Package['libnss-extrausers'],
      source  => 'puppet:///modules/nss/nsswitch.conf';
  }

  file {
    '/etc/mdns.allow':
      require => Package['libnss-extrausers'],
      source  => 'puppet:///modules/nss/mdns.allow';
  }

  Package <| title == libnss-extrausers |>
}
