class image::desktop {
  include image::bundle::desktop,
          packages,
          xorg_driver_switches

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == proposed
                  or title == repo
                  or title == x2go
                  or title == xorg-updates |>

  # apply package definitions listed in packages with "puavo" or "ubuntu" tags
  Package <| tag == puavo
          or tag == ubuntu |>

  # keep the "extra", "opinsys", "partner" and "restricted" packages out
  Package <| tag == extra
          or tag == opinsys
          or tag == partner
          or tag == restricted |> { ensure => purged, }
}
