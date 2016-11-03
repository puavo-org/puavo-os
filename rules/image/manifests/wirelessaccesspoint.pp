class image::wirelessaccesspoint {
  include ::image::bundle::basic
  include ::packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == proposed
                  or title == repo |>

  # wirelessaccesspoint should be able to function as a wireless accesspoint
  # (puavo-wlanap*) and as a digital signage system (iivari-client)
  Package <| tag == 'tag_admin'
          or tag == 'tag_basic'
          or title == iivari-client |>
}
