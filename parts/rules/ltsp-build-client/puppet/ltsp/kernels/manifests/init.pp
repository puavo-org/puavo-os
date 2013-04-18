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

  case $lsbdistcodename {
    'quantal': {
      $default_kernel = '3.8.8.opinsys1'

      default_kernel_link {
        [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
          require => Packages::Kernel_package_for_version[$default_kernel];
      }

      Packages::Kernel_package_for_version <| title == $default_kernel |>
    }
  }
}
