class pipewire_jack {
  include ::packages

  exec {
    '/sbin/ldconfig':
      refreshonly => true;
  }

  file {
    '/etc/ld.so.conf.d/pipewire-jack.conf':
      require => Package['pipewire-jack'],
      notify  => Exec['/sbin/ldconfig'],
      source  => 'puppet:///modules/pipewire_jack/pipewire-jack.conf';
  }
}
