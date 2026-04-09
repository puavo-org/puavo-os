class munin {
  include ::packages

  file {
    '/etc/nginx/sites-available/munin':
      mode    => '0644',
      require => [ Package['munin'], Package['munin-node'] ],
      source  => 'puppet:///modules/munin/nginx_conf';
  }

  Package <|
       title == 'munin'
    or title == 'munin-node'
  |>
}
