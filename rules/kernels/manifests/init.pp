class kernels {
  include ::kernels::dkms
  include ::kernels::grub_update
  include ::packages

  $kernel_versions = {
    'default' => '6.1.0-31-amd64',
    'crisp'   => '6.12.9+bpo-amd64',
  }

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

  define install_kernel {
    $kernel_alias = $title

    ::kernels::all_kernel_links {
      $kernel_alias:
        kernel  => $kernel_versions[$kernel_alias],
        require => Packages::Kernels::Kernel_package[$kernel_alias];
    }

    Packages::Kernels::Kernel_package <| title == $kernel_alias |>
  }
}
