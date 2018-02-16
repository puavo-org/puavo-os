class hwquirks {
  include ::packages

  file {
    '/usr/share/puavo-conf/hwquirk-overwrites':
      ensure  => directory,
      require => Package['puavo-conf'];

    '/usr/share/puavo-conf/hwquirk-overwrites/50-pm-lidswitchdocked.json':
      source => 'puppet:///modules/hwquirks/50-pm-lidswitchdocked.json';

    '/usr/share/puavo-conf/hwquirk-overwrites/70-i915-disable-drrs.json':
      source => 'puppet:///modules/hwquirks/70-i915-disable-drrs.json';
  }

  Package <| title == puavo-conf |>
}
