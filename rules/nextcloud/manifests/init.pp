class nextcloud {
  ::puavo_pkg::packages

  file { '/etc/Nextcloud': ensure => directory; }
  file {
    '/etc/Nextcloud/Nextcloud.conf':
       source  => 'puppet:///modules/desktop/Nextcloud.conf';
  }

  Puavo_pkg::Install <| title == nextcloud-desktop |>
}
