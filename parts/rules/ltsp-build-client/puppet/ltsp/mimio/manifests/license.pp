class mimio::license {
  require packages,
          puavo_external_files

  puavo_external_files::external_file {
    '/var/opt/mimio/global/global.reg':
      external_file_name => 'mimio_license_global';

    '/var/opt/mimio/global/shared.reg':
      external_file_name => 'mimio_license_shared';
  }

  Package <| tag == whiteboard-mimio |>
}
