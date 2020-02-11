class kernels::grub_update {
  include ::packages

  # Make sure grub-pc is installed, and then remove some update-grub
  # configurations that are unnecessary in ltsp clients, but prevent the
  # installation of alternative kernels.
  # XXX (Where should this really be fixed?)

  $grub_update_files = [ '/etc/kernel/postinst.d/zz-update-grub'
                       , '/etc/kernel/postrm.d/zz-update-grub' ]

  file {
    $grub_update_files:
      ensure  => absent,
      require => [ Package['grub-efi-ia32-bin']
                 , Package['grub-efi-amd64-bin']
                 , Package['grub-pc-bin'] ];
  }

  Package <| tag == 'tag_kernel' |> {
    require +> File[ $grub_update_files ],
  }

  Package <| title == grub-efi-ia32-bin
          or title == grub-efi-amd64-bin
          or title == grub-pc-bin |>
}
