class image::bundle::bootserver {
  include ::bootserver_autopoweron
  # include ::bootserver_backup         # XXX needs work
  include ::packages

  Package <| tag == tag_puavo_bootserver |>
}
