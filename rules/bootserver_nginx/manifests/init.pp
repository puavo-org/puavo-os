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

    '/usr/share/nginx/www/index.html':
      content => template('bootserver_nginx/index.html'),
      mode    => 0644;
  }

  service {
    'nginx':
      ensure => running;
  }
}
