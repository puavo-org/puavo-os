class bootserver_network_interfaces::install {
  include ::bootserver_network_interfaces

  $sentinel_file = '/etc/network/.interfaces.installed_by_puppet'

  exec {
    'setup network interfaces':
      command => "/usr/bin/touch '${sentinel_file}' \
      && /bin/cp /etc/network/interfaces.by_puppet /etc/network/interfaces;",
      creates => $sentinel_file,
      require => File['/etc/network/interfaces.by_puppet'];
  }
}
