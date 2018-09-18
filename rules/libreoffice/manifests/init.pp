class libreoffice {
  include ::dpkg
  require ::packages

  $libre_dir = '/usr/lib/libreoffice'

  dpkg::simpledivert {
    [ "${libre_dir}/program/resource/fi/LC_MESSAGES/sfx.mo",  ]: ;
  }

  file {
    "${libre_dir}/program/resource/fi/LC_MESSAGES/sfx.mo":
      require => Dpkg::Simpledivert["${libre_dir}/program/resource/fi/LC_MESSAGES/sfx.mo"],
      source  => 'puppet:///modules/libreoffice/sfx.mo';
  }

  Package <| title == libreoffice |>
}

