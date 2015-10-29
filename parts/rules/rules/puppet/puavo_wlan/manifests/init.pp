class puavo_wlan {
  include puavo_wlan::rt2800usb_shutdown_workaround
  require packages

  Package <| title == puavo-wlanap |>
}
