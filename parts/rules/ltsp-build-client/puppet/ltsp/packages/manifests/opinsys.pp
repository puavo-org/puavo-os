class packages::opinsys {
  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == partner
                  or title == private-archive
                  or title == repo |>

  # apply all package definitions listed in packages
  Package <| |>
}
