class acroread {
  include dpkg,
          packages

  dpkg::divert {
    '/usr/share/applications/acroread.desktop':
      dest => '/usr/share/applications/acroread.desktop.dist';
  }

  file {
    '/usr/share/applications/acroread.desktop':
      require => [ Dpkg::Divert['/usr/share/applications/acroread.desktop']
                 , Package['acroread'] ],
      source  => 'puppet:///modules/acroread/acroread.desktop';
  }

  Package <| title == acroread |>
}
