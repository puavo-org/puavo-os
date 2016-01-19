class promethean {
  include puavo_external_files

  # XXX These directories are probably set up by the Promethean packages, but
  # XXX currently we do not have those as a standard part of the device image,
  # XXX so we have to set this up this way:
  file {
    [ '/etc/xdg'
    , '/etc/xdg/Promethean'
    , '/etc/xdg/Promethean/ActivInspire' ]:
      ensure => directory;
  }

  puavo_external_files::external_file {
    '/etc/xdg/Promethean/ActivInspire/.inspire_license.xml':
      external_file_name => 'promethean_license',
      require            => File['/etc/xdg/Promethean/ActivInspire'];
  }
}
