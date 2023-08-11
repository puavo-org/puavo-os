class docker {
  include ::docker::collabora
  include ::docker::nextcloud

  file {
    '/etc/puavo-docker':
      ensure => directory;

    '/etc/puavo-docker/docker-compose.yml.tmpl':
      require => File['/etc/puavo-docker/files/Dockerfile.nextcloud'],
      source  => 'puppet:///modules/docker/docker-compose.yml.tmpl';

    '/etc/puavo-docker/files':
      ensure => directory;
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
