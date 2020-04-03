class puavo_external_files {
  include ::packages
  include ::puavo_external_files

  define external_file ($external_file_name) {
    $original_path = $title

    file {
      $original_path:
        ensure  => link,
        require => Package['puavo-ltsp-client'],
        target  => "/state/external_files/${external_file_name}";
    }
  }

  file {
    '/etc/puavo-external-files-actions.d':
      ensure => directory;
  }

  Package <| title == puavo-ltsp-client |>
}
