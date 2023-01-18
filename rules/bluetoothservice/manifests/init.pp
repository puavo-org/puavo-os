class bluetoothservice {
  # Systemd fails to start bluetooth service because StateDirectory is symlinked at '/state'.
  # So lets override 'StateDirectory' value.

  file {
    '/etc/systemd/system/bluetooth.service.d':
      ensure => directory;

    '/etc/systemd/system/bluetooth.service.d/bluetooth_override.conf':
      source => 'puppet:///modules/bluetoothservice/bluetooth_override.conf';
  }
}
