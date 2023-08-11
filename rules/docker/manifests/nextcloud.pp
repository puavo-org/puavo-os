class docker::nextcloud {
  include ::docker::postgres
  include ::puavo_conf
}
