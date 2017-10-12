class hwquirks {
  include ::packages

  file {
    '/usr/share/puavo-conf/hwquirk-overwrites':
      ensure  => directory,
      require => Package['puavo-conf'];

    '/usr/share/puavo-conf/hwquirk-overwrites/hp_stream_pro.json':
      source => 'puppet:///modules/hwquirks/hp_stream_pro.json';
  }

  Package <| title == puavo-conf |>
}
