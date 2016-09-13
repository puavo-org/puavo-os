class image::desktop {
  include image::bundle::desktop,
          packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == libreoffice-5-0
                  or title == proposed
                  or title == repo
                  or title == x2go
                  or title == xorg-updates |>

  Package <| tag == 'tag_puavo'
          or tag == 'tag_ubuntu' |>

  # keep these packages out
  Package <| tag == 'tag_extra'
          or tag == 'tag_opinsys'
          or tag == 'tag_partner'
          or tag == 'tag_restricted' |> { ensure => purged, }
}
