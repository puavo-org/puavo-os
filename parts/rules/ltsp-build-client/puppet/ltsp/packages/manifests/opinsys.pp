class packages::opinsys {
  # XXX this class perhaps belongs elsewhere?

  include organisation_apt_repositories

  # apply all package definitions with "opinsys"-tag listed in packages
  Package <| tag == opinsys |> {
    require => [ Apt::Repository['liitu'], Exec['apt update'], ],
  }

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == liitu |>
}
