class desktop::mimedefaults {
  include ::packages

  file {
    '/etc/xdg/mimeapps.list':
       require => Package['xdg-user-dirs'],
       source  => 'puppet:///modules/desktop/mimeapps.list';
  }

  Package <| title == xdg-user-dirs |>
}
