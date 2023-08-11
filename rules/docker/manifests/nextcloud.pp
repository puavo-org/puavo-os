class docker::nextcloud {
  include ::docker::postgres
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-docker-nextcloud.json':
      source => 'puppet:///modules/docker/puavo-docker-nextcloud.json';
  }
}
