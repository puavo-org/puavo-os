class smartboard {
  require packages

  file {
    '/etc/xdg/autostart/smart_1-_Service.desktop':
      content => template('smartboard/smart_1-_Service.desktop'),
      mode    => 755;

    '/etc/xdg/autostart/smart_1-_Tools.desktop':
      content => template('smartboard/smart_1-_Tools.desktop'),
      mode    => 755;

    '/usr/local/bin/start_smartboard_service':
      content => template('smartboard/start_smartboard_service'),
      mode    => 755;

    '/usr/local/bin/start_smartboard_tools':
      content => template('smartboard/start_smartboard_tools'),
      mode    => 755;
  }

  Package <| tag == whiteboard-smartboard |>
}
