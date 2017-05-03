# Puavo Sysinfo Collector
# Collects host information for the login screen

class puavo_sysinfo_collector {
  file {
    '/usr/sbin/puavo-sysinfo-collector':
      source => 'puppet:///modules/puavo_sysinfo_collector/puavo-sysinfo-collector',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  file {
    '/lib/systemd/system/puavo-sysinfo-collector.service':
      source => 'puppet:///modules/puavo_sysinfo_collector/puavo-sysinfo-collector.service',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
  }

  # link for systemd
  file {
    '/etc/systemd/system/multi-user.target.wants/puavo-sysinfo-collector.service':
      target => '/lib/systemd/system/puavo-sysinfo-collector.service',
      ensure => 'link',
  }
}
