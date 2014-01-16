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

  case $lsbdistcodename {
    'quantal': {
      $default_kernel = '3.10.23.opinsys1'
      $edge_kernel = '3.12.4.opinsys1'

      default_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernel_package_for_version[$default_kernel];
      }

      edge_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernel_package_for_version[$edge_kernel];
      }

      Packages::Kernel_package_for_version <| title == $default_kernel |>
      Packages::Kernel_package_for_version <| title == $edge_kernel |>
    }
  }
}
