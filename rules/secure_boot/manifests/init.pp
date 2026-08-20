class secure_boot {
  $base_directory = '/etc/puavo-secure-boot'

  file {
    [ $base_directory, ]:
      ensure => directory;

    "${base_directory}/db":
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/secure_boot/db';
  }
}
