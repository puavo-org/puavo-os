class docker {
  include ::docker::collabora
  include ::docker::nextcloud

  file {
    '/etc/puavo-docker':
      ensure => directory;

    '/etc/puavo-docker/docker-compose.yml.tmpl':
      source => 'puppet:///modules/docker/docker-compose.yml.tmpl';
  }

  ::puavo_conf::definition {
    'puavo-docker-nextcloud.json':
      source => 'puppet:///modules/docker/puavo-docker-nextcloud.json';
  }

  Package <|
       title == "docker-compose"
    or title == "docker.io"
  |>
}
