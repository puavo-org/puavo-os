class flatpak {
  include ::packages

  file {
    [ '/var/lib/flatpak', '/var/lib/flatpak/.puavo' ]:
      ensure => directory;
  }

  define install {
    $flatpak_package = $title

    exec {
      "flatpak install -y flathub $flatpak_package && touch /var/lib/flatpak/.puavo/flatpak-${flatpak_package}":
        creates => "/var/lib/flatpak/.puavo/flatpak-${flatpak_package}",
        require => [ Exec['flathub setup'], Package['flatpak'], ];
    }
  }

  exec {
    'flathub setup':
      command => 'flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && touch /var/lib/flatpak/.puavo/flathub_setup_done',
      creates => '/var/lib/flatpak/.puavo/flathub_setup_done',
      require => Package['flatpak'];
  }

  Package <| title == flatpak |>
}
