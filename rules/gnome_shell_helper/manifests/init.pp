class gnome_shell_helper {
  include ::dpkg

  ::dpkg::simpledivert { '/usr/bin/gnome-shell': ; }

  file {
    '/usr/bin/gnome-shell':
      mode    => '0755',
      require => [ Dpkg::Simpledivert['/usr/bin/gnome-shell'],
		   Package['gnome-shell'], ],
      source  => 'puppet:///modules/gnome_shell_helper/gnome-shell';
  }

  Package <| title == gnome-shell |>
}
