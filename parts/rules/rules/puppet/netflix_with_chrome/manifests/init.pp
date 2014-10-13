class netflix_with_chrome {
  include packages

  file {
    '/usr/local/bin/netflix':
      mode    => 755,
      require => Package['google-chrome-beta'],
      source  => 'puppet:///modules/netflix_with_chrome/netflix';

    '/usr/local/share/applications/netflix.desktop':
      require => File['/usr/local/bin/netflix'],
      source  => 'puppet:///modules/netflix_with_chrome/netflix.desktop';
  }

  Package <| title == google-chrome-beta |>
}
