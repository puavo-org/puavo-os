class bootserver_nginx {
  include ::packages

  File { require => Package['nginx'] }

  define enable {
    $service_name = $title

    file {
      "/etc/nginx/sites-enabled/${service_name}":
	ensure => link,
	target => "/etc/nginx/sites-available/${service_name}";
    }
  }

  bootserver_nginx::enable {
    'default':
      ;
  }

  file {
    '/etc/nginx/sites-available/default':
      content => template('bootserver_nginx/default_site'),
      mode    => '0644';

    # Newer version of nginx ships the default index.html file in
    # /usr/share/nginx/html directory instead of
    # /usr/share/nginx/www.
    [ '/usr/share/nginx/html'
    , '/usr/share/nginx/www' ]:
      ensure => directory;

    '/usr/share/nginx/html/index.html':
      content => template('bootserver_nginx/index.html'),
      mode    => '0644';

    '/usr/share/nginx/www/index.html':
      ensure => link,
      target => '/usr/share/nginx/html/index.html';
  }

  Package <| title == nginx |>
}
