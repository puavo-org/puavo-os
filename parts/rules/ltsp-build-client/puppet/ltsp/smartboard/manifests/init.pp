class smartboard {
  require packages
  include smartboard::config,
          smartboard::notebook_cache_wrapper,
          smartboard::startup

  Package <| tag == whiteboard-smartboard |>
}
