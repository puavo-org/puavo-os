class nextcloud {
  include ::puavo_pkg::packages

  file {
    '/etc/Nextcloud':
      ensure => directory;

    '/etc/Nextcloud/Nextcloud.conf':
      require => Puavo_pkg::Install['nextcloud-desktop'],
      source  => 'puppet:///modules/nextcloud/Nextcloud.conf';
  }

  Puavo_pkg::Install <| title == 'nextcloud-desktop' |>
}
