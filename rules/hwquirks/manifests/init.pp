class hwquirks {
  include ::packages

  file {
    '/usr/share/puavo-conf/hwquirk-overwrites':
      ensure  => directory,
      require => Package['puavo-conf'];

    '/usr/share/puavo-conf/hwquirk-overwrites/01-pm-lidswitchdocked.json':
      source => 'puppet:///modules/hwquirks/01-pm-lidswitchdocked.json';
  }

  Package <| title == puavo-conf |>
}
