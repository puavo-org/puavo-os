class secure_boot {
  $base_directory = '/etc/secure-boot'
  $certificates_directory = "${base_directory}/certificates"

  file {
    $base_directory:
      ensure => directory;

    $certificates_directory:
      ensure  => directory,
      require => File[$base_directory];

    "${certificates_directory}/pk":
      ensure => directory,
      source => 'puppet:///modules/secure_boot/pk',
      recurse => true;

    "${certificates_directory}/kek":
      ensure => directory,
      source => 'puppet:///modules/secure_boot/kek',
      recurse => true;

    "${certificates_directory}/db":
      ensure => directory,
      source => 'puppet:///modules/secure_boot/db',
      recurse => true;

    "${certificates_directory}/dbx":
      ensure => directory,
      source => 'puppet:///modules/secure_boot/dbx',
      recurse => true;
  }
}
