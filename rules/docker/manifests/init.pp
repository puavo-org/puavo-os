class docker {
  include ::apt::docker
  include ::docker::collabora
  include ::docker::nextcloud
  include ::packages

  $docker_ip = '172.17.0.1'
  $docker_ip_with_cidr = "${docker_ip}/16"

  $deb_version_suffix = "${facts['os']['distro']['release']['major']}~${facts['os']['distro']['codename']}"
  $docker_version = '5:29.1.5-1'

  $containerd_io_version         = "2.2.1-1~debian.${deb_version_suffix}"
  $docker_buildx_plugin_version  = "0.30.1-1~debian.${deb_version_suffix}"
  $docker_compose_plugin_version = "5.0.1-1~debian.${deb_version_suffix}"
  $docker_deb_version            = "${docker_version}~debian.${deb_version_suffix}"

  file {
    '/etc/apt/preferences.d/50-docker.pref':
      content => template('docker/50-docker.pref');

    '/etc/puavo-docker':
      ensure => directory;

    '/etc/puavo-docker/docker-compose.yml.tmpl':
      content => template('docker/docker-compose.yml.tmpl'),
      require => File['/etc/puavo-docker/files/Dockerfile.nextcloud'];

    '/etc/puavo-docker/files':
      ensure => directory;

    '/etc/puavo-docker/rsnapshot.conf':
      source => 'puppet:///modules/docker/rsnapshot.conf';

    '/etc/systemd/system/puavo-docker.service':
      source => 'puppet:///modules/docker/puavo-docker.service';

    '/etc/systemd/system/puavo-docker.timer':
      source => 'puppet:///modules/docker/puavo-docker.timer';

    '/etc/systemd/system/timers.target.wants/puavo-docker.timer':
      ensure  => 'link',
      require => [ File['/etc/systemd/system/puavo-docker.timer']
                 , Package['systemd'] ],
      target  => '/etc/systemd/system/puavo-docker.timer';

    '/usr/local/sbin/puavo-backup-docker':
      mode    => '0755',
      require => [ File['/etc/puavo-docker/rsnapshot.conf']
                 , Package['docker-ce']
                 , Package['rsnapshot'], ],
      source  => 'puppet:///modules/docker/puavo-backup-docker';

    '/usr/local/sbin/puavo-docker':
      mode    => '0755',
      require => [ File['/etc/puavo-docker/docker-compose.yml.tmpl']
                 , Package['puavo-sharedir-manager']
                 , Package['ruby-net-ldap'] ],
      source  => 'puppet:///modules/docker/puavo-docker';

    '/usr/local/sbin/puavo-restore-docker':
      mode    => '0755',
      require => Package['docker-ce'],
      source  => 'puppet:///modules/docker/puavo-restore-docker';
  }

  ::puavo_conf::definition {
    'puavo-docker.json':
      source => 'puppet:///modules/docker/puavo-docker.json';
  }

  # Packages from the Docker repository
  package {
    'containerd.io':              ensure => $containerd_io_version;
    'docker-buildx-plugin':       ensure => $docker_buildx_plugin_version;
    'docker-ce':                  ensure => $docker_deb_version;
    'docker-ce-cli':              ensure => $docker_deb_version;
    'docker-ce-rootless-extras':  ensure => $docker_deb_version;
    'docker-compose-plugin':      ensure => $docker_compose_plugin_version;
  }
}
