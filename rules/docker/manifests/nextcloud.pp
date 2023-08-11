class docker::nextcloud {
  include ::docker::postgres
  include ::puavo_conf

  file {
    '/etc/puavo-docker/files/Dockerfile.nextcloud':
      source  => 'puppet:///modules/docker/Dockerfile.nextcloud';
  }
}
