class bootserver_nginx {
  define enable {
    $service_name = $title

    file {
      "/etc/nginx/sites-enabled/${service_name}":
	ensure => link,
	notify => Exec['reload nginx'],
	target => "/etc/nginx/sites-available/${service_name}";
    }
  }

  bootserver_nginx::enable {
    'default':
      ;
  }

  exec {
    'reload nginx':
      command     => '/usr/sbin/service nginx reload',
      refreshonly => true,
      require     => Service['nginx'];
  }

  file {
    '/etc/nginx/sites-available/default':
      content => template('bootserver_nginx/default_site'),
      mode    => 0644,
      notify  => Exec['reload nginx'];

    # Newer version of nginx ships the default index.html file in
    # /usr/share/nginx/html directory instead of
    # /usr/share/nginx/www.
    [ '/usr/share/nginx/html'
    , '/usr/share/nginx/www' ]:
      ensure => directory;

    '/usr/share/nginx/html/index.html':
      content => template('bootserver_nginx/index.html'),
      mode    => 0644;

    '/usr/share/nginx/www/index.html':
      ensure => link,
      target => '/usr/share/nginx/html/index.html';
  }

  service {
    'nginx':
      ensure => running;
  }
}
