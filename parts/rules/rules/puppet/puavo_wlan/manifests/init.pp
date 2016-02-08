class puavo_wlan {
  # include puavo_wlan::rt2800usb_shutdown_workaround	# XXX not needed?
  require packages

  Package <| title == puavo-wlanap |>

}
