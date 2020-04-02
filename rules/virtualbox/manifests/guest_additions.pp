class virtualbox::guest_additions {
  include ::kernels
  include ::packages

  exec {
    '/usr/local/lib/install-virtualbox-guest-additions && /usr/bin/touch /var/opt/.virtuabox-guest-additions-installed':
      creates => '/var/opt/.virtuabox-guest-additions-installed',
      require => [ File['/etc/login.defs'],
                   File['/usr/local/lib/install-virtualbox-guest-additions'],
                   Kernels::All_kernel_links['default'] ];
  }

  file {
    # We must use SYS_UID_MAX lower than 999, otherwise "vboxadd"-user
    # uid will conflict with (optional) "guest"-user uid.
    '/etc/login.defs':
      source => 'puppet:///modules/virtualbox/login.defs';

    '/usr/local/lib/install-virtualbox-guest-additions':
      mode    => '0755',
      require => Package['p7zip-full'],
      source  => 'puppet:///modules/virtualbox/install-virtualbox-guest-additions';
  }

  Package <| title == p7zip-full |>
}
