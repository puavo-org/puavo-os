class install_hp_plugins {
  include ::packages

  exec {
    'puavo-download-hp-plugins':
      command => '/usr/local/sbin/puavo-download-hp-plugins',
      require => File['/usr/local/sbin/puavo-download-hp-plugins'],
      unless  => '/bin/grep -qx "installed = 1" /var/lib/hp/hplip.state';
  }

  file {
    '/etc/udev/rules.d/40-libsane.rules':
      mode    => '0644',
      require => Exec['puavo-download-hp-plugins'];
    '/etc/udev/rules.d/S99-2000S1.rules':
      mode    => '0644',
      require => Exec['puavo-download-hp-plugins'];
  }

  exec {
    'fix-hplip-udev-issues':
      command => 'sed -i "s/libsane_rules_end/libsane_usb_rules_end/g"\
        /etc/udev/rules.d/40-libsane.rules /etc/udev/rules.d/S99-2000S1.rules',
      require => Exec['puavo-download-hp-plugins'],
      onlyif => ['grep -o libsane_rules_end /etc/udev/rules.d/40-libsane.rules \
        /etc/udev/rules.d/S99-2000S1.rules'];
  }

  file {
    '/usr/local/sbin/puavo-download-hp-plugins':
      mode    => '0755',
      require => [ Package['expect'], Package['hplip'] ],
      source  => 'puppet:///modules/install_hp_plugins/puavo-download-hp-plugins';
  }

  Package <| title == expect or title == hplip |>
}
