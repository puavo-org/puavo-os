# Puavo Sysinfo Collector
# Collects host information for the login screen

class puavo_sysinfo_collector {
  # sysinfo collector files
  file {
    '/etc/dbus-1/system.d/org.puavo.sysinfo.conf':
      source => 'puppet:///modules/puavo_sysinfo_collector/org.puavo.sysinfo.conf';

    '/etc/systemd/system/multi-user.target.wants/puavo-sysinfo-collector.service':
      ensure  => 'link',
      require => File['/lib/systemd/system/puavo-sysinfo-collector.service'],
      target  => '/lib/systemd/system/puavo-sysinfo-collector.service';

    '/lib/systemd/system/puavo-sysinfo-collector.service':
      require => File['/usr/sbin/puavo-sysinfo-collector'],
      source  => 'puppet:///modules/puavo_sysinfo_collector/puavo-sysinfo-collector.service';

    '/usr/sbin/puavo-sysinfo-collector':
      mode    => '0755',
      require => File['/etc/dbus-1/system.d/org.puavo.sysinfo.conf'],
      source  => 'puppet:///modules/puavo_sysinfo_collector/puavo-sysinfo-collector';
  }

  # sysinfo sender files
  file {
    '/etc/systemd/system/multi-user.target.wants/puavo-send-sysinfo-to-puavo.service':
      ensure  => 'link',
      require => File['/lib/systemd/system/puavo-send-sysinfo-to-puavo.service'],
      target  => '/lib/systemd/system/puavo-send-sysinfo-to-puavo.service';

    '/lib/systemd/system/puavo-send-sysinfo-to-puavo.service':
      require => File['/usr/sbin/puavo-send-sysinfo-to-puavo'],
      source  => 'puppet:///modules/puavo_sysinfo_collector/puavo-send-sysinfo-to-puavo.service';

    '/usr/sbin/puavo-send-sysinfo-to-puavo':
      mode    => '0755',
      require => File['/etc/systemd/system/multi-user.target.wants/puavo-sysinfo-collector.service'],
      source  => 'puppet:///modules/puavo_sysinfo_collector/puavo-send-sysinfo-to-puavo';
  }
}
