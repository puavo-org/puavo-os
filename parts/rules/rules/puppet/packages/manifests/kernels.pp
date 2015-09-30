class packages::kernels {
  include kernels::dkms,
          packages

  define kernel_package ($package_tag='',
                         $with_extra=true,
                         $with_dbg=false,
                         $pkgarch='',
                         $dkms_modules=[]) {
    $version = $title

    $pkgarch_postfix = $pkgarch ? { '' => '', default => ":$pkgarch", }

    $extra_packages = $with_extra ? {
      true  => [ "linux-image-extra-${version}${pkgarch_postfix}" ],
      false => [],
    }

    $dbg_packages = $with_dbg ? {
      true  => [ "linux-image-${version}-dbg${pkgarch_postfix}" ],
      false => [],
    }

    $packages = [ "linux-headers-${version}${pkgarch_postfix}"
                , "linux-image-${version}${pkgarch_postfix}"
                , $extra_packages
                , $dbg_packages ]

    # Clunky tricks to retain compatibility the Puppet version (2.7.11)
    # in Precise, newer puppet versions could use iterations.
    $dkms_modules_install_titles = regsubst($dkms_modules,
                                            '$',
                                            " for ${version}")
    kernels::dkms::install_dkms_module_for_kernel {
      $dkms_modules_install_titles:
        kernel_version => $version;
    }

    @package {
      $packages:
        tag => $package_tag ? {
                 ''      => 'kernel',
                 default => [ 'kernel', $package_tag, ],
               };
    }
  }
}
