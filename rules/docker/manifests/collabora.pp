class docker::collabora {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-docker-collabora.json':
      source => 'puppet:///modules/docker/puavo-docker-collabora.json';
  }
}
