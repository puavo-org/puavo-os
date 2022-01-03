class nextcloud {
  include ::packages

  file {
    '/etc/Nextcloud/Nextcloud.conf':
       source  => 'puppet:///modules/desktop/Nextcloud.conf';
  }

}
