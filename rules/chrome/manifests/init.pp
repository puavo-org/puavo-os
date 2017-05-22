class chrome {
  include ::puavo_pkg::packages

  file {
    '/usr/bin/google-chrome-stable':
      mode    => '0755',
      require => Puavo_pkg::Install['google-chrome'],
      source  => 'puppet:///modules/chrome/google-chrome-stable';
  }

  Puavo_pkg::Install <| title == google-chrome |>
}
