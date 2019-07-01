class puavo_conf {
  include ::initramfs
  include ::packages

  file {
    '/etc/puavo-conf/hooks':
      ensure => directory;
  }

  define definition ($source) {
    $definition_name = $title

    file {
      "/usr/share/puavo-conf/definitions/${definition_name}":
        notify  => Exec['update initramfs'],
        require => Package['puavo-conf'],
        source  => $source;
    }
  }

  define hook ($script) {
    $puavo_conf_key = $title

    file {
      "/etc/puavo-conf/hooks/${puavo_conf_key}":
        ensure => link,
        target => "../scripts/${script}";
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

    '/etc/puavo-conf/scripts/.preinit.bootserver':
      require => Package['puavo-conf'],
      source  => 'puppet:///modules/puavo_conf/puavo-conf_scripts_preinit.bootserver';
  }

  Package <| title == puavo-conf |>
}
