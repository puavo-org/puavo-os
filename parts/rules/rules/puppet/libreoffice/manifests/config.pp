class libreoffice::config {
  require packages

  file {
    '/etc/puavo-external-files-actions.d/libreoffice':
      content => template('libreoffice/puavo-external-files-actions.d/libreoffice'),
      mode    => 755;
  }

  Package <| tag == libreoffice-writer |>
}
