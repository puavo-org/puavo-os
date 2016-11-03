class puavo_external_files {
  include ::packages

  define external_file ($external_file_name) {
    $original_path = $title

    file {
      $original_path:
        ensure  => link,
        require => Package['puavo-ltsp-client'],
        target  => "/state/external_files/${external_file_name}";
    }
  }

  Package <| title == puavo-ltsp-client |>
}
