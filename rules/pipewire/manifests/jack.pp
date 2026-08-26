class pipewire::jack {
  include ::packages

  exec {
    '/sbin/ldconfig for pipewire-jack.conf':
      command => '/sbin/ldconfig',
      unless  => 'test /etc/ld.so.cache -nt /etc/ld.so.conf.d/pipewire-jack.conf';
  }

  file {
    '/etc/ld.so.conf.d/pipewire-jack.conf':
      before  => Exec['/sbin/ldconfig for pipewire-jack.conf'],
      require => Package['pipewire-jack'],
      source  => 'puppet:///modules/pipewire/pipewire-jack.conf';
  }
}
