class ebeam::startup {
  require packages

  file {
    '/etc/xdg/autostart/ebeam.desktop':
      content => template('ebeam/ebeam.desktop');

    '/usr/local/bin/start_ebeam':
      content => template('ebeam/start_ebeam'),
      mode    => 755;
  }

  Package <| tag == whiteboard-ebeam |>
}
