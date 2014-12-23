class kernels {
  include kernels::grub_update
  require packages

  define kernel_link ($kernel, $linkname, $linksuffix) {
    file {
      "/boot/${linkname}${linksuffix}":
        ensure  => link,
        require => Packages::Kernels::Kernel_package[$kernel],
        target  => "${linkname}-${kernel}";
    }

    Packages::Kernels::Kernel_package <| title == $kernel |>
  }

  define all_kernel_links ($kernel='') {
    $subname = $title

    $linksuffix = $subname ? { 'default' => '', default => "-$subname", }

    kernel_link {
      "initrd.img-${kernel}-${subname}":
        kernel => $kernel, linkname => 'initrd.img', linksuffix => $linksuffix;

      "nbi.img-${kernel}-${subname}":
        kernel => $kernel, linkname => 'nbi.img', linksuffix => $linksuffix;

      "vmlinuz-${kernel}-${subname}":
        kernel => $kernel, linkname => 'vmlinuz', linksuffix => $linksuffix;
    }
  }

  $default_kernel = $lsbdistcodename ? {
    'precise' => '3.2.0-69-generic',
    'trusty'  => '3.13.0-41-generic',
  }

  $legacy_kernel = $lsbdistcodename ? {
    'precise' => $default_kernel,
    'trusty'  => '3.2.0-70-generic-pae',
  }

  $edge_kernel   = $default_kernel
  $stable_kernel = $default_kernel

  case $lsbdistcodename {
    'precise', 'trusty': {
      all_kernel_links {
        'default': kernel => $default_kernel;
        'edge':    kernel => $edge_kernel;
        'legacy':  kernel => $legacy_kernel;
        'stable':  kernel => $stable_kernel;
      }
    }
  }
}
