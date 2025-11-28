class secure_boot {
  $base_directory = '/etc/puavo-secure-boot'
  $certificates_directory = "${base_directory}/certificates"

  file {
    [ $base_directory, $certificates_directory, ]:
      ensure => directory;

    "${certificates_directory}/db":
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/secure_boot/db';

    "${certificates_directory}/dbx":
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/secure_boot/dbx';

    "${certificates_directory}/kek":
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/secure_boot/kek';

    "${certificates_directory}/pk":
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/secure_boot/pk';
  }
}
