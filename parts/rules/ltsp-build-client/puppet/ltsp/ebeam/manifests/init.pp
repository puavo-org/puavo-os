class ebeam {
  require packages
  include ebeam::startup

  Package <| tag == whiteboard-ebeam |>
}
