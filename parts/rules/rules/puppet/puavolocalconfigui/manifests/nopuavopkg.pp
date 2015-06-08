class puavolocalconfigui::nopuavopkg inherits puavolocalconfigui {
  File['/etc/puavo-local-config/puavo-local-config-ui.conf'] {
    content => template('puavolocalconfigui/puavo-local-config-ui-nopuavopkg.conf'),
  }
}
