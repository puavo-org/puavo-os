class packages::abitti {
  include ::packages

  @package {
    [ 'live-boot'
    , 'live-boot-initramfs-tools'
    , 'live-config'
    , 'live-config-systemd'
    , 'live-tools' ]:
      ensure => present;
  }
}
