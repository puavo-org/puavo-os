class kernels {
  include ::kernels::dkms
  include ::kernels::grub_update
  include ::packages

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

  # Our each Debian release has the backported kernel named with a different
  # alias so that if a host is using a backported kernel, it will move on
  # to the default kernel in the next major release.  Thus far we have used:
  #   Ubuntu Trusty:   edge
  #   Debian Stretch:  fresh
  #   Debian Buster:   current
  #   Debian Bullseye: recent
  #   Debian Bookworm: crisp
  #   Debian Trixie:   ?

  $default_kernel = '6.12.21-amd64'
  # XXX $crisp_kernel   = '6.11.5-amd64'        # XXX missing from Trixie

  ::kernels::all_kernel_links {
    'default': kernel => $default_kernel;
    # 'crisp':   kernel => $crisp_kernel;       # XXX missing from Trixie
  }
}
