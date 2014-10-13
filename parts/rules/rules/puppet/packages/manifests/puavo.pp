class packages::puavo {
  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == repo
                  or title == x2go |>

  # apply package definitions listed in packages with "puavo" or "ubuntu" tags
  Package <| tag == puavo
          or tag == ubuntu |>

  # keep the "opinsys", "partner" and "restricted" packages out
  Package <| tag == opinsys
          or tag == partner
          or tag == restricted |> { ensure => purged, }
}
