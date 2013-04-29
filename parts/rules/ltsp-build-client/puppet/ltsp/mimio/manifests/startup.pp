class mimio::startup {
  require packages

  file {
    '/etc/xdg/autostart/mimio-mimiosys.desktop':
      content => template('mimio/mimio-mimiosys.desktop');

    '/usr/local/bin/start_mimiosys':
      content => template('mimio/start_mimiosys'),
      mode    => 755;
  }

  Package <| tag == whiteboard-mimio |>
}
