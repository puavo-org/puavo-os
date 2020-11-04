class virtualbox::guest_additions {
  include ::kernels
  include ::packages

  exec {
    '/usr/local/lib/install-virtualbox-guest-additions && /usr/bin/touch /var/opt/.virtuabox-guest-additions-installed':
      creates => '/var/opt/.virtuabox-guest-additions-installed',
      require => [ File['/etc/login.defs'],
                   File['/usr/local/lib/install-virtualbox-guest-additions'],
                   Kernels::All_kernel_links['current'],
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

  # We do not need to rebuild kernel modules for virtualbox guest
  # additions.  Do not try to use "service", we do not run
  # systemd inside the container in image build, thus the service
  # can not be disabled through the puppet "service"-type.
  file {
    '/etc/systemd/system/multi-user.target.wants/vboxadd.service':
       ensure  => absent,
       require => [ Exec['install virtualbox guest additions'],
                    Package['systemd'] ];
  }

  Package <| title == p7zip-full
          or title == systemd |>
}
