class bootserver_ltspimages {
  include ::bootserver_nginx

  bootserver_nginx::enable { 'ltsp-images': ; }

  exec {
    '/usr/sbin/puavo-bootserver-generate-nbd-exports':
      loglevel => debug,
      require  => File['/opt/ltsp/images'];
  }

  exec {
    '/usr/sbin/puavo-bootserver-update-tftpboot --prune':
      loglevel => debug,
      require  => File['/opt/ltsp/images'];
  }

  file {
    [ '/opt/ltsp', '/opt/ltsp/images', ]:
      ensure => directory;
  }
}
