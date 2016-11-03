class crash_reporting {
  include ::packages

  file {
    '/etc/default/whoopsie':
      content => template('crash_reporting/etc_default_whoopsie'),
      require => Package['whoopsie'];
  }

  Package <| title == whoopsie |>
}
