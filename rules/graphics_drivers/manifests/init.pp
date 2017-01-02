class graphics_drivers {
  include ::packages
  include ::puavo_conf

  $glx_packages = [ 'glx-alternative-mesa', 'libgl1-mesa-glx', 'update-glx' ]

  $nvidia_packages = $debianversioncodename ? {
                       'jessie' => [ 'nvidia-304xx-kernel-dkms'
                                   , 'nvidia-340xx-kernel-dkms' ],
                       default  => [ 'nvidia-304xx-kernel-dkms'
                                   , 'nvidia-340xx-kernel-dkms'
                                   , 'nvidia-375xx-kernel-dkms' ],
                     }

  ::puavo_conf::script {
    'setup_graphics_drivers':
      require => [ Package[$glx_packages], Package[$nvidia_packages], ],
      source  => 'puppet:///modules/graphics_drivers/setup_graphics_drivers';
  }

  exec {
    '/usr/sbin/update-glx --set glx /usr/lib/mesa-diverted':
      require => Package[$glx_packages],
      unless  => '/usr/sbin/update-glx --query glx | grep -Fqx "Value: /usr/lib/mesa-diverted"';
  }

  Package <| title == $glx_packages or title == $nvidia_packages |>
}
