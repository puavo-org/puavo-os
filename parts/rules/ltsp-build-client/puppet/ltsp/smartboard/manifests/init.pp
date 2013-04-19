class smartboard {
  require packages
  include smartboard::config,
          smartboard::startup

  Package <| tag == whiteboard-smartboard |>
}
