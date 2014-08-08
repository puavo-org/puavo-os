class packages::opinsysextra {
  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == private-archive
                  or title == private-repo
                  or title == partner
                  or title == repo
                  or title == x2go |>

  # apply all package definitions listed in packages
  Package <| |>

  # remove all packages that are "restricted"
  Package <| tag == restricted |> { ensure => purged, }

  # except install all those with "extra"
  Package <| tag == extra |> { ensure => present, }
}
