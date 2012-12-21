class packages::opinsys {
  # XXX this class perhaps belongs elsewhere?

  include packages

  # apply all package definitions with "opinsys"-tag listed in packages
  Package <| tag == opinsys |>

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == liitu |>
}
