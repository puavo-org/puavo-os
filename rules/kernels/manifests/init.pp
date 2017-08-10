class kernels {
  include ::kernels::dkms
  include ::kernels::grub_update
  require ::packages

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

    ::kernels::kernel_link {
      "initrd.img-${kernel}-${subname}":
        kernel => $kernel, linkname => 'initrd.img', linksuffix => $linksuffix;

      "vmlinuz-${kernel}-${subname}":
        kernel => $kernel, linkname => 'vmlinuz', linksuffix => $linksuffix;
    }
  }

  # "grubsafe"-kernel should be a kernel which is safe from
  # this bug: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=869771.
  $default_kernel  = '4.9.0-3-amd64'
  $edge_kernel     = $default_kernel
  $grubsafe_kernel = '4.9.0-2-amd64'
  $legacy_kernel   = '3.16.0-4-amd64'

  ::kernels::all_kernel_links {
    'default':  kernel => $default_kernel;
    'edge':     kernel => $edge_kernel;
    'grubsafe': kernel => $grubsafe_kernel;
    'legacy':   kernel => $legacy_kernel;
  }
}
