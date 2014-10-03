class ssh_client {
  include packages

  file {
    '/etc/ssh/ssh_config':
      content => template('ssh_client/ssh_config'),
      require => Package['openssh-client'];

    # this contains the builder key, remove it, this is not used and causes
    # login issues
    '/etc/ssh/ssh_known_hosts':
      ensure => absent;
  }

  Package <| title == openssh-client |>
}
