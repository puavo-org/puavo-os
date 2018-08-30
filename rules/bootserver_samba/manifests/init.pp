class bootserver_samba {
  include ::bootserver_slapd
  include ::packages
  include ::puavo_conf

  file {
    '/etc/pam.d/samba':
      source => 'puppet:///modules/bootserver_samba/etc_pam.d_samba';

    '/etc/systemd/system/smbd.service.d':
      ensure => directory;

    '/etc/systemd/system/smbd.service.d/override.conf':
      require => File['/usr/local/lib/puavo-service-wait-for-slapd'],
      source  => 'puppet:///modules/bootserver_samba/smbd_override.conf';
  }

  ::puavo_conf::script {
    'setup_samba':
      source => 'puppet:///modules/bootserver_samba/setup_samba';
  }

  Package <| title == samba or title == winbind |>
}
