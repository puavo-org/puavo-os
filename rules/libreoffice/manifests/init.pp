class libreoffice {
  include ::dpkg
  include ::packages

  # apply a translation fix for Finnish Libreoffice environment

  $libreoffice_dir = '/usr/lib/libreoffice'
  $fi_msg_dir      = "${libreoffice_dir}/program/resource/fi/LC_MESSAGES"
  $src_object      = "${fi_msg_dir}/.sfx.po"
  $target_object   = "${fi_msg_dir}/sfx.mo"

  dpkg::simpledivert { $target_object: ; }

  exec {
    "msgfmt --output-file ${target_object} ${src_object}":
      onlyif  => "/usr/bin/test ${target_object} -ot ${src_object}",
      require => [ Dpkg::Simpledivert[$target_object]
                 , File[$src_object]
                 , Package['gettext'] ];
  }

  file {
    $src_object:
      require => Package['libreoffice'],
      source  => 'puppet:///modules/libreoffice/sfx.po';
  }

  Package <| title == gettext
          or title == libreoffice |>
}
