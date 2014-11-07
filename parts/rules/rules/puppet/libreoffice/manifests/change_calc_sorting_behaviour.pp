class libreoffice::change_calc_sorting_behaviour {
  # see https://bugs.launchpad.net/ubuntu/+source/libreoffice/+bug/1389858
  # for rationale

  require dpkg,
	  packages

  dpkg::simpledivert {
    '/usr/lib/libreoffice/share/registry/main.xcd':
      before => File['/usr/lib/libreoffice/share/registry/main.xcd'];
  }

  file {
    '/usr/lib/libreoffice/share/registry/main.xcd':
      source => 'puppet:///modules/libreoffice/main.xcd';
  }

  Package <| title == libreoffice-common |>
}
