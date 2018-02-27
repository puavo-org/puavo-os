class image::bundle::bootserver {
  include ::bootserver_autopoweron
  include ::packages

  Package <| tag == tag_puavo_bootserver |>
}
