class bootserver_hostname {
  include puavo

  exec {
    'set hostname':
      command     => '/bin/hostname --file /etc/hostname',
      refreshonly => true,
      require     => File['/etc/hostname'];
  }

  file {
    '/etc/hostname':
      content => "${puavo_hostname}\n",
      notify  => Exec['set hostname'];       
  }
}
