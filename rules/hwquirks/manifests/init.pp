class hwquirks {
  include ::packages

  file {
    '/usr/share/puavo-conf/hwquirk-overwrites':
      ensure  => directory,
      require => Package['puavo-conf'];

    '/usr/share/puavo-conf/hwquirk-overwrites/40-intel-audio.json':
      source => 'puppet:///modules/hwquirks/40-intel-audio.json';

    '/usr/share/puavo-conf/hwquirk-overwrites/41-hp-3gmodem.json':
      source => 'puppet:///modules/hwquirks/41-hp-3gmodem.json';

    '/usr/share/puavo-conf/hwquirk-overwrites/50-pm-lidswitchdocked.json':
      source => 'puppet:///modules/hwquirks/50-pm-lidswitchdocked.json';

    '/usr/share/puavo-conf/hwquirk-overwrites/60-disable-grub-theme.json':
      source => 'puppet:///modules/hwquirks/60-disable-grub-theme.json';

    '/usr/share/puavo-conf/hwquirk-overwrites/70-i915-disable-drrs.json':
      source => 'puppet:///modules/hwquirks/70-i915-disable-drrs.json';
  }

  Package <| title == puavo-conf |>
}
