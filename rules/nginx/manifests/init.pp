class nginx {
  include ::packages

  file {
    '/etc/nginx/nginx.conf':
      content => template('nginx/nginx.conf'),
      require => Package['nginx'];
  }

  Package <| title == nginx |>
}
