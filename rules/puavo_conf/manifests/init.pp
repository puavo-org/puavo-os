class puavo_conf {
  include ::packages

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
