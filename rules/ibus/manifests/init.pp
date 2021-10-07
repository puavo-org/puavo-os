class ibus {
  include ::packages

  file {
    '/etc/xdg/autostart/ibus-anthy-gnome-initial-setup.desktop':
      ensure  => absent,
      require => Package['ibus-anthy'];

    '/usr/local/bin/puavo-ibus':
      mode    => '0755',
      require => Package['ibus-anthy'],
      source  => 'puppet:///modules/ibus/puavo-ibus';
  }

  Package <| title == ibus-anthy |>
}
