class puavolocalconfigui::nolocalusers inherits puavolocalconfigui {
  File['/etc/puavo-local-config/puavo-local-config-ui.conf'] {
    content => template('puavolocalconfigui/puavo-local-config-ui-nolocalusers.conf'),
  }
}
