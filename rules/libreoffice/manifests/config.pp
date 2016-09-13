class libreoffice::config {
  require packages

  file {
    '/etc/puavo-external-files-actions.d/libreoffice':
      content => template('libreoffice/puavo-external-files-actions.d/libreoffice'),
      mode    => '0755';
  }

  Package <| tag == 'tag_libreoffice-writer' |>
}
