class packages::kernels {
  include kernels::dkms,
          packages

  define kernel_package ($package_name='',
                         $package_tag='',
                         $with_dbg=false,
                         $dkms_modules=[]) {
    $version = $title

    $dbg_packages = $with_dbg ? {
      true  => [ "linux-image-${version}-dbg" ],
      false => [],
    }

    $image_package = $package_name ? {
                       ''      => [ "linux-image-${version}" ],
                       default => [ $package_name ],
                     }

    $packages = [ "linux-headers-${version}"
                , $image_package
                , $dbg_packages ]

    # Clunky tricks to retain compatibility the Puppet version (2.7.11)
    # in Precise, newer puppet versions could use iterations.
    $dkms_modules_install_titles = regsubst($dkms_modules,
                                            '$',
                                            " for ${version}")
    kernels::dkms::install_dkms_module_for_kernel {
      $dkms_modules_install_titles:
        kernel_packages => $packages,
        kernel_version  => $version;
    }

    @package {
      $packages:
        tag => $package_tag ? {
                 ''      => 'tag_kernel',
                 default => [ 'tag_kernel', $package_tag, ],
               };
    }
  }
}
