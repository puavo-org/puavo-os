class graphics_drivers {
  include ::packages

  exec {
    '/usr/bin/update-alternatives --set glx /usr/lib/mesa-diverted':
      require => [ Package['libgl1-mesa-glx']
                 , Package['nvidia-kernel-dkms'] ],
      unless  => '/usr/bin/update-alternatives --query glx | grep -Fqx "Value: /usr/lib/mesa-diverted"';
  }

  Package <| title == libgl1-mesa-glx
          or title == nvidia-kernel-dkms |>
}
