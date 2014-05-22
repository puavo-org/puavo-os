class packages::puavo {
  require apt::repositories,
          organisation_apt_repositories

  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels |>

  # apply package definitions listed in packages with "puavo" or "ubuntu" tags
  Package <| tag == puavo
          or tag == ubuntu |>
}
