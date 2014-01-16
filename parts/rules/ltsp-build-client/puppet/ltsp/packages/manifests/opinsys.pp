class packages::opinsys {
  # XXX this class perhaps belongs elsewhere?  really!

  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == repo
                  or title == archive
                  or title == private-archive
                  or title == kernels |>
}
