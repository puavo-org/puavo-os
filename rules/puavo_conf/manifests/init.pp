class puavo_conf {
  include ::initramfs
  include ::packages

  define definition ($source) {
    $definition_name = $title

    file {
      "/usr/share/puavo-conf/definitions/${definition_name}":
        notify  => Exec['update initramfs'],
        require => Package['puavo-conf'],
        source  => $source;
    }
  }

  define script ($source) {
    $scriptname = $title

    file {
      "/etc/puavo-conf/scripts/${scriptname}":
        mode    => '0755',
        require => Package['puavo-conf'],
        source  => $source;
    }
  }

  file {
    '/etc/puavo-conf/scripts/.preinit':
      require => Package['puavo-conf'],
      source  => 'puppet:///modules/puavo_conf/puavo-conf_scripts_preinit';
  }

  Package <| title == puavo-conf |>
}
