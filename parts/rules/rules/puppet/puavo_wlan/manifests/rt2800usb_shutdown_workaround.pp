class puavo_wlan::rt2800usb_shutdown_workaround {
  file {
    '/etc/init.d/kill-rt2800usb':
      mode   => 755,
      source => 'puppet:///modules/puavo_wlan/kill-rt2800usb';

    [ '/etc/rc0.d/S02kill-rt2800usb', '/etc/rc6.d/S02kill-rt2800usb', ]:
      ensure  => link,
      require => File['/etc/init.d/kill-rt2800usb'],
      target  => '../init.d/kill-rt2800usb';
  }
}
