class bootserver_ltspimages {
  include ::packages
  include ::puavo_conf

  file {
    '/usr/local/lib/puavo-handle-image-changes':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_ltspimages/puavo-handle-image-changes';

    # This must be created somewhere so that setup_state_partition links
    # it under /state.
    '/var/lib/tftpboot/ltsp':
      ensure => directory;
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
