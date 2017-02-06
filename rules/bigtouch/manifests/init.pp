class bigtouch {
  include ::packages
  include ::puavo_pkg::packages

  file {
    '/usr/share/gnome-shell/extensions/bigtouch-ux@puavo.org':
      recurse => true,
      require => Package['gnome-shell-extensions'],
      source  => 'puppet:///modules/bigtouch/bigtouch-ux@puavo.org';
  }

  Package <|
       title == cheese
    or title == evince
    or title == gnome-calculator
    or title == gnome-clocks
    or title == gnome-shell-extensions
    or title == onboard
    or title == openboard
  |>

  Puavo_pkg::Install <| title == google-chrome |>
}
