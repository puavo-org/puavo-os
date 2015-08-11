class packages::kernels {
  define kernel_package ($package_tag='',
                         $with_extra=true,
                         $with_dbg=false,
                         $pkgarch='') {
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

    @package {
      $packages:
        tag => $package_tag ? {
                 ''      => 'kernel',
                 default => [ 'kernel', $package_tag, ],
               };
    }
  }
}
