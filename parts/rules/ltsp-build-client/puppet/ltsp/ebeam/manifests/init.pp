class ebeam {
  require packages
  include ebeam::startup

  file {
    '/usr/share/applications/ebeam.desktop':
      content => template('ebeam/ebeam.desktop');
  }

  Package <| tag == whiteboard-ebeam |>
}
