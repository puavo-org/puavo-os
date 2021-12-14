class udisks2::mindstormsev3 {
  include ::packages

  file {
    '/etc/udisks2/mount_options.conf':
      content => template('udisks2/mount_options.rules'),
      require => [ Package['udisks2'] ];
  }

  Package <| title == udisks2 |>
}
