class packages::thinclient {
  require apt::repositories,
          organisation_apt_repositories

  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == private-archive
                  or title == repo |>

  # apply only thinclient package definitions listed in packages
  Package <| tag == thinclient |>
}
