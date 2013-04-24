class oracle_java {
  include organisation_apt_repositories,
          packages

  $distfile_name = 'jdk-7u21-linux-i586.tar.gz'
  $full_url_path =
    "${organisation_apt_repositories::distfiles_path}/$distfile_name"
  $full_target_path = "/var/tmp/oracle-jjava-distfiles/$distfile_name"

  exec {
    'fetch oracle-java distfile':
      before  => Package['oracle-java7-installer'],
      command => "/usr/bin/wget -O ${full_target_path}.tmp $full_url_path && /bin/mv ${full_target_path}.tmp $full_target_path",
      creates => $full_target_path,
      require => File['/var/tmp/oracle-jjava-distfiles'];
  }

  file {
    '/var/tmp/oracle-jjava-distfiles':
      ensure => directory;
  }

  Package <| title == oracle-java7-installer |>
}
