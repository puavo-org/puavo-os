class graphics_drivers {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_graphics_drivers':
      source => 'puppet:///modules/graphics_drivers/setup_graphics_drivers';
  }

  $nvidia_packages = $debianversioncodename ? {
                       'jessie' => [ 'nvidia-304xx-kernel-dkms'
                                   , 'nvidia-340xx-kernel-dkms' ],
                       default  => [ # XXX broken 'nvidia-304xx-kernel-dkms'
                                     'nvidia-340xx-kernel-dkms'
                                   , 'nvidia-375xx-kernel-dkms' ],
                     }

  exec {
    '/usr/bin/update-alternatives --set glx /usr/lib/mesa-diverted':
      require => [ Package['libgl1-mesa-glx']
                 , Package[$nvidia_packages] ],
      unless  => '/usr/bin/update-alternatives --query glx | grep -Fqx "Value: /usr/lib/mesa-diverted"';
  }

  Package <| title == libgl1-mesa-glx
          or title == $nvidia_packages |>
}
