class bootserver_ltspimages {
  include ::bootserver_nginx
  include ::packages
  include ::puavo_conf

  ::bootserver_nginx::enable { 'ltsp-images': ; }

  file {
    '/usr/local/lib/puavo-handle-image-changes':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_ltspimages/puavo-handle-image-changes';

    # This must be created somewhere so that setup_state_partition links
    # it under /state.
    '/var/lib/tftpboot/ltsp':
      ensure  => directory,
      replace => false;
  }
}
