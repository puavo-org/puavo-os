class ssh_server {
  include ::adm
  include ::packages

  file {
    '/etc/ssh/sshd_config.d/restrict-groups.conf':
      content => template('ssh_server/restrict-groups.conf');
  }

  Package <| title == 'openssh-server' |>
}
