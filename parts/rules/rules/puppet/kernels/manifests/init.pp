class kernels {
  include kernels::dkms,
          kernels::grub_update
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
    'jessie' => '3.16.0-4-amd64',
  }

  $hwgen2_kernel = $lsbdistcodename ? {
    'jessie' => $default_kernel,
    default  => $default_kernel,
  }

  $hwgen3_kernel = $lsbdistcodename ? {
    'jessie' => $default_kernel,
    default  => $default_kernel,
  }

  $legacy_kernel = $lsbdistcodename ? {
    'jessie' => $default_kernel,
    default  => $default_kernel,
  }

  $edge_kernel = $lsbdistcodename ? {
    'jessie' => $default_kernel,
    default  => $default_kernel,
  }

  $stable_kernel = $default_kernel

  all_kernel_links {
    'default': kernel => $default_kernel;
    'edge':    kernel => $edge_kernel;
    'hwgen2':  kernel => $hwgen2_kernel;
    'hwgen3':  kernel => $hwgen3_kernel;
    'legacy':  kernel => $legacy_kernel;
    'stable':  kernel => $stable_kernel;
  }
}
