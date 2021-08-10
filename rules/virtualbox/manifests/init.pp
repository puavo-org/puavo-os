class virtualbox {
  include ::packages

  define build_driver ($kernel_version) {
    $label = $title

    $sentinel_path = "/usr/lib/modules/${kernel_version}/.vboxdrv.built"

    exec {
      "create virtualbox driver modules for kernel $kernel_version":
        command => "/usr/lib/virtualbox/puavo-vboxdrv.sh puavo_build_modules ${kernel_version} && /usr/bin/touch ${sentinel_path}",
        creates => $sentinel_path,
        require => [ File['/usr/lib/virtualbox/puavo-vboxdrv.sh']
                   , Kernels::All_kernel_links[$label]
                   , Package['virtualbox-6.1'] ];
    }

  }

  file {
    '/usr/lib/virtualbox/puavo-vboxdrv.sh':
      mode    => '0755',
      require => Package['virtualbox-6.1'],
      source  => 'puppet:///modules/virtualbox/puavo-vboxdrv.sh';
  }

  ::virtualbox::build_driver {
    'default': kernel_version => $kernels::default_kernel;
  }

  Package <| title == "virtualbox-6.1" |>
}
