class kernels {
  include kernels::grub_update
  require packages

  define default_kernel_link {
    $filename = $title

    file {
      "/boot/$filename":
       ensure => link,
       target => "${filename}-${kernels::default_kernel}";
    }
  }

  define edge_kernel_link {
    $filename = $title

    file {
      "/boot/$filename-edge":
       ensure => link,
       target => "${filename}-${kernels::edge_kernel}";
    }
  }

  define stable_kernel_link {
    $filename = $title

    file {
      "/boot/$filename-stable":
       ensure => link,
       target => "${filename}-${kernels::stable_kernel}";
    }
  }

  case $lsbdistcodename {
    'trusty': {
      $default_kernel = '3.13.0-36-generic'

      default_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernels::Kernel_package[$default_kernel];
      }

      Packages::Kernels::Kernel_package <| title == $default_kernel |>
    }
  }
}
