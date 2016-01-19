class bootserver_ssh_server {

  file {
    '/etc/ssh/sshd_config':
      content => template('bootserver_ssh_server/sshd_config'),
      mode    => 0644,
      notify  => Service['ssh'];
  }

  service {
    'ssh':
      enable => true,
      ensure => running;
  }
}
