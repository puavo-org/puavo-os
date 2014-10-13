class packages::kernels {
  define kernel_package ($package_tag='', $with_extra=true, $with_dbg=false) {
    $version = $title

    $extra_packages = $with_extra ? {
      true  => [ "linux-image-extra-$version" ],
      false => [],
    }

    $dbg_packages = $with_dbg ? {
      true  => [ "linux-image-$version-dbg" ],
      false => [],
    }

    $packages = [ "linux-headers-$version"
                , "linux-image-$version"
                , $extra_packages
                , $dbg_packages ]

    @package {
      $packages:
        tag => $package_tag ? {
                 ''      => 'kernel',
                 default => [ 'kernel', $package_tag, ],
               },
    }
  }
}
