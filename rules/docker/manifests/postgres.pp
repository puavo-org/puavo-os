class docker::postgres {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-docker-postgres.json':
      source => 'puppet:///modules/docker/puavo-docker-postgres.json';
  }
}
