class image::thinclient {
  include image::bundle::basic,
          packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == repo |>

  # apply only thinclient package definitions listed in packages
  Package <| tag == thinclient |>
}
