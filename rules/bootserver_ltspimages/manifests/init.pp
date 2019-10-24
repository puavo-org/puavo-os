class bootserver_ltspimages {
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
