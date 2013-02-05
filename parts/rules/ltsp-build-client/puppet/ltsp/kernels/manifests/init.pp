class kernels {
  include kernels::grub_update
  require packages

  $default_kernel = $lsbdistcodename ? {
                      'precise' => '3.2.0-37-generic',
                      'quantal' => '3.5.0-23-generic',
                    }

  define default_kernel_link {
    $filename = $title

    file {
      "/boot/$filename":
       ensure => link,
       target => "${filename}-${kernels::default_kernel}";
    }
  }

  default_kernel_link {
    [ 'initrd.img', 'nbi.img', 'vmlinuz', ]:
      require => Packages::Kernel_package_for_version[$default_kernel];
  }

  Packages::Kernel_package_for_version <| title == $default_kernel |>
}
