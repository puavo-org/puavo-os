class secure_boot {
  $base_directory = '/etc/puavo-secure-boot'

  file {
    [ $base_directory, ]:
      ensure => directory;

    "${base_directory}/db":
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/secure_boot/db';

    "${base_directory}/db.esl":
      source => 'puppet:///modules/secure_boot/db.esl';

    "${base_directory}/built":
      source => 'puppet:///modules/secure_boot/built';
  }
}
