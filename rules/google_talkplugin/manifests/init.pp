class google_talkplugin {
  include ::packages

  file {
    '/etc/default/google-talkplugin':
      ensure => present,
      before => Package['google-talkplugin'];
  }

  Package <| title == google-talkplugin |>
}
