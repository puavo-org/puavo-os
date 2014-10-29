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

  $default_kernel = $lsbdistcodename ? {
    'precise' => '3.2.0-69-generic',
    'trusty'  => '3.13.0-36-generic',
  }

  $edge_kernel = $lsbdistcodename ? {
    'precise' => $default_kernel,
    'trusty'  => $default_kernel,
  }

  $stable_kernel = $lsbdistcodename ? {
    'precise' => $default_kernel,
    'trusty'  => $default_kernel,
  }

  case $lsbdistcodename {
    'precise', 'trusty': {

      default_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernels::Kernel_package[$default_kernel];
      }

      edge_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernels::Kernel_package[$edge_kernel];
      }

      stable_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernels::Kernel_package[$stable_kernel];
      }

      Packages::Kernels::Kernel_package <| title == $default_kernel |>
      Packages::Kernels::Kernel_package <| title == $edge_kernel    |>
      Packages::Kernels::Kernel_package <| title == $stable_kernel  |>
    }
  }
}
