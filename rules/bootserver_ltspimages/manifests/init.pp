class bootserver_ltspimages {
  include ::packages
  include ::puavo_conf

  file {
    '/usr/local/lib/puavo-handle-image-changes':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_ltspimages/puavo-handle-image-changes';
  }

  ::puavo_conf::script {
    'setup_incrond':
      require => [ File['/usr/local/lib/puavo-handle-image-changes']
                 , Package['incron'] ],
      source  => 'puppet:///modules/bootserver_ltspimages/setup_incrond';
  }

  Package <| title == incron |>
}


#  include ::bootserver_nginx
#
#  bootserver_nginx::enable { 'ltsp-images': ; }
#
#  exec {
#    '/usr/sbin/puavo-bootserver-generate-nbd-exports':
#      loglevel => debug,
#      require  => File['/opt/ltsp/images'];
#  }
#
#  exec {
#    '/usr/sbin/puavo-bootserver-update-tftpboot --prune':
#      loglevel => debug,
#      require  => File['/opt/ltsp/images'];
#  }
#
#  file {
#    [ '/opt/ltsp', '/opt/ltsp/images', ]:
#      ensure => directory;
#  }
