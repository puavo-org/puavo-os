class image::builder {
  include image::bundle::basic,
	  packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == repo |>

  # apply only builder package definitions listed in packages
  Package <| tag == admin
          or tag == basic
          or title == puavo-devscripts
          or title == puavo-image-tools
          or title == puavo-rules |>
}
