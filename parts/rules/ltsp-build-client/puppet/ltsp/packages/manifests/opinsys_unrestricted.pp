class packages::opinsys_unrestricted {
  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == private-archive
                  or title == private-repo
                  or title == repo
                  or title == x2go |>

  # apply all package definitions listed in packages
  Package <| |>

  Package <| tag == restricted |> { ensure => purged, }
}
