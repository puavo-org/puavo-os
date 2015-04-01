class disable_suspend_by_tags {
  include packages

  file {
    '/etc/pm/sleep.d/02_tags_test':
      mode    => 755,
      require => Package['pm-utils'],
      source  => 'puppet:///modules/disable_suspend_by_tags/02_tags_test';
  }

  Package <| title == pm-utils |>
}
