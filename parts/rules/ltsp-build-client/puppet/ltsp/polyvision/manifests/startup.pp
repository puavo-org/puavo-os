class polyvision::startup {
  require packages

  file {
    '/etc/xdg/autostart/polyvision-pvd.desktop':
      content => template('polyvision/polyvision-pvd.desktop');

    '/etc/xdg/autostart/polyvision-cdfnu.desktop':
      content => template('polyvision/polyvision-cdfnu.desktop');

    '/usr/local/bin/start_polyvision_pvd':
      content => template('polyvision/start_polyvision_pvd'),
      mode    => 755;

    '/usr/local/bin/start_polyvision_cdfnu':
      content => template('polyvision/start_polyvision_cdfnu'),
      mode    => 755;
  }

  Package <| tag == whiteboard-polyvision |>
}
