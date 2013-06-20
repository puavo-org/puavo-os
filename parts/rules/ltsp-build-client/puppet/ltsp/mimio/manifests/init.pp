class mimio {
  require packages
  include mimio::license,
          mimio::startup

  Package <| tag == whiteboard-mimio |>
}
