class puavo_external_files {
  require packages

  define external_file ($external_file_name) {
    $original_path = $title

    file {
      $original_path:
        ensure => link,
        target => "/state/external_files/${external_file_name}";
    }
  }
}
