class keyboard_hw_quirks {
  include initramfs,
          packages

  exec {
    '/bin/udevadm hwdb --update':
      onlyif => '/usr/bin/test /lib/udev/hwdb.bin -ot /lib/udev/hwdb.d/60-puavo-keyboard.hwdb',
      require => [ File['/lib/udev/hwdb.d/60-puavo-keyboard.hwdb']
                 , Package['udev'] ];
  }

  file {
    '/lib/udev/hwdb.d/60-puavo-keyboard.hwdb':
      require => Package['udev'],
      source  => 'puppet:///modules/keyboard_hw_quirks/60-puavo-keyboard.hwdb';

    '/usr/share/puavo-conf/parameters/puavo-rules-keyboard_hw_quirks.json':
      notify  => Exec['initramfs::update'],
      require => Package['puavo-conf'],
      source  => 'puppet:///modules/keyboard_hw_quirks/puavo-conf-parameters.json';

    '/usr/share/puavo-ltsp/init-puavo.d/94-puavo-keyboard-quirks':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/keyboard_hw_quirks/94-puavo-keyboard-quirks';
  }

  Package <| title == puavo-conf |>
  Package <| title == puavo-ltsp-client |>
  Package <| title == udev |>
}
