class bootserver_samba {
  include ::bootserver_slapd
  include ::packages
  include ::puavo_conf

  file {
    # workaround a bug when using dhclient on inet0
    '/etc/dhcp/dhclient-enter-hooks.d/samba':
      mode    => '0755',
      require => Package['samba'],
      source  => 'puppet:///modules/bootserver_samba/etc_dhcp_dhclient-enter-hooks.d_samba';

    '/etc/pam.d/samba':
      source => 'puppet:///modules/bootserver_samba/etc_pam.d_samba';

    '/etc/systemd/system/smbd.service.d':
      ensure  => directory,
      require => Package['systemd'];

    '/etc/systemd/system/smbd.service.d/override.conf':
      require => File['/usr/local/lib/puavo-service-wait-for-slapd'],
      source  => 'puppet:///modules/bootserver_samba/smbd_override.conf';
  }

  ::puavo_conf::script {
    'setup_samba':
      source => 'puppet:///modules/bootserver_samba/setup_samba';
  }

  Package <| title == samba or title == systemd or title == winbind |>
}
